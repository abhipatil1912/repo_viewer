import 'dart:io';

import 'package:dio/dio.dart';

extension DioErrorX on DioError {
  /// returns true if error is of type socket exception
  bool get isNoConnectionError {
    return (type == DioErrorType.other) && (error is SocketException);
  }
}
