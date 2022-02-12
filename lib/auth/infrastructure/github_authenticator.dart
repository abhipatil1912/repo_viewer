import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart';

import '../../core/infrastructure/dio_extensions.dart';
import '../../core/shared/encoders.dart';
import '../domain/auth_failure.dart';
import 'credentials_storage/credentials_storage.dart';

/// custom http client class to set headers
class GithubOAuthHttpClient extends http.BaseClient {
  final httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return httpClient.send(request);
  }
}

/// git hub authenticator
class GithubAuthenticator {
  final CredentialsStorage _credentialsStorage;
  final Dio _dio;
  GithubAuthenticator(
    this._credentialsStorage,
    this._dio,
  );

  static const clientId = 'd403001a37b713ea3ced';
  static const clientSecret = '2e67b5d10aee40a90bf976ec3832b78f17e73266';
  static const scopes = ['read:user', 'repo'];
  static final authorizationEndpoint =
      Uri.parse('https://github.com/login/oauth/authorize');
  static final tokenEndpoint =
      Uri.parse('https://github.com/login/oauth/access_token');
  static final revocationEndPoint =
      Uri.parse('https://api.github.com/applications/$clientId/token');
  static final redirectUrl = Uri.parse('http://localhost:3000/callback');

  /// returns a stored nullable credentials
  Future<Credentials?> getSignInCredentials() async {
    try {
      final storedCredentials = await _credentialsStorage.read();
      if (storedCredentials != null) {
        if (storedCredentials.canRefresh && storedCredentials.isExpired) {
          final failureOrCredentials = await refresh(storedCredentials);
          return failureOrCredentials.fold((l) => null, (r) => r);
        }
      }
      return storedCredentials;
    } on PlatformException {
      return null;
    }
  }

  Future<bool> isSignedIn() =>
      getSignInCredentials().then((cred) => cred != null);

  AuthorizationCodeGrant createGrant() {
    return AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
      httpClient: GithubOAuthHttpClient(),
    );
  }

  Uri getAuthorizationUrl(AuthorizationCodeGrant grant) {
    return grant.getAuthorizationUrl(redirectUrl, scopes: scopes);
  }

  Future<Either<AuthFailure, Unit>> handleAuthorizationResponse(
    AuthorizationCodeGrant grant,
    Map<String, String> queryParams,
  ) async {
    try {
      // this method exchange the auth code for access token
      // & returns http client object containing all the headers with tokens
      final httpClient = await grant.handleAuthorizationResponse(queryParams);
      await _credentialsStorage.save(httpClient.credentials);
      return right(unit);
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server("${e.error} : ${e.description}"));
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Unit>> signOut() async {
    final accessToken = await _credentialsStorage
        .read()
        .then((credentials) => credentials?.accessToken);

    final usernameAndPassword =
        stringToBase64.encode('$clientId:$clientSecret');

    try {
      try {
        _dio.deleteUri(
          revocationEndPoint,
          data: {
            'access_token': accessToken,
          },
          options: Options(
            headers: {'Authorization': 'basic $usernameAndPassword'},
          ),
        );
      } on DioError catch (e) {
        if (e.isNoConnectionError) {
          log("Failed to revoke token");
        } else {
          rethrow;
        }
      }
      await _credentialsStorage.clear();
      return right(unit);
    } on PlatformException {
      return left(const AuthFailure.storage());
    }
  }

  Future<Either<AuthFailure, Credentials>> refresh(
    Credentials credentials,
  ) async {
    try {
      final newCred = await credentials.refresh(
        identifier: clientId,
        secret: clientSecret,
        httpClient: GithubOAuthHttpClient(),
      );
      await _credentialsStorage.save(newCred);
      return right(newCred);
    } on PlatformException {
      return left(const AuthFailure.storage());
    } on FormatException {
      return left(const AuthFailure.server());
    } on AuthorizationException catch (e) {
      return left(AuthFailure.server("${e.error} : ${e.description}"));
    }
  }
}
