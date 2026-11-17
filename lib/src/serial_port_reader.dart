part of 'serial_port.dart';

/// Reads incoming data from a serial port on a background isolate.
///
/// The port must already be open. Subscribe to [stream] to receive each
/// non-empty chunk of bytes, and call [close] when the reader is no longer
/// needed.
class SerialPortReader {
  final _receivePort = ReceivePort();
  final _sendPort = Completer<SendPort?>();

  final _controller = StreamController<Uint8List>();

  /// A stream of non-empty byte chunks received from the serial port.
  ///
  /// Native read errors are reported as [SerialPortException] errors on this
  /// stream.
  Stream<Uint8List> get stream => _controller.stream;

  /// Starts reading from [port] with a native read buffer of [bufferSize]
  /// bytes.
  ///
  /// [port] must be open before creating the reader. The reader owns its
  /// background isolate and should be stopped with [close]. Closing or
  /// disposing [port] also stops the reader.
  ///
  /// Throws a [StateError] if [port] has been disposed or is closing.
  SerialPortReader(SerialPort port, {int bufferSize = 1024}) {
    final address = port._handle.address;
    if (port._lifecycle.closePending) {
      throw StateError('Cannot read from a SerialPort that is closing');
    }

    _receivePort.listen((message) {
      if (message is SendPort) _sendPort.complete(message);
      if (message is Uint8List) _controller.add(message);
      if (message is SerialPortException) _controller.addError(message);
    });

    // The port must outlive any native call this reader's isolate makes, so
    // it is closed and freed only after the isolate has exited.
    port._lifecycle.readers.add(this);

    final closePort = ReceivePort();
    closePort.listen((_) {
      closePort.close();
      _dispose();
      port._readerExited(this);
    });

    Isolate.spawn(
      _startRemoteIsolate,
      _IsolateParams(_receivePort.sendPort, address, bufferSize),
      onExit: closePort.sendPort,
    ).then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        // No isolate, so no exit notification either.
        closePort.close();
        _sendPort.complete(null);
        _controller.addError(error, stackTrace);
        _dispose();
        port._readerExited(this);
      },
    );
  }

  /// Stops the background reader and completes when its stream is closed.
  ///
  /// Await this before closing or disposing the port to close the port
  /// without delay.
  Future<void> close() async {
    _stop();
    await _controller.done;
  }

  void _stop() {
    _sendPort.future.then((sendPort) => sendPort?.send(_StopSignal()));
  }

  void _dispose() {
    _controller.close();
    _receivePort.close();
  }

  static Future<void> _startRemoteIsolate(_IsolateParams params) async {
    // Setup
    final bufferSize = params.bufferSize;
    final port = Pointer<sp.Port>.fromAddress(params.portAddress);
    final buffer = calloc<Uint8>(bufferSize);

    // Stop signal setup
    final receivePort = ReceivePort();
    bool running = true;
    final listener = receivePort.listen((message) {
      if (message is _StopSignal) running = false;
    });
    params.sendPort.send(receivePort.sendPort);

    // Main loop
    while (running) {
      try {
        // Returns as soon as any data is available, rather than waiting for
        // the buffer to fill. The timeout bounds how long a stop request
        // can go unnoticed.
        final len = assertReturn(
          sp.blockingReadNext(port, buffer.cast(), bufferSize, 100),
        );
        if (len > 0) {
          final bytes = buffer.asTypedList(len);
          params.sendPort.send(bytes);
        }
      } catch (e) {
        final error = getLastError();
        if (error != null) params.sendPort.send(error);
        break;
      }
      // Let the event loop run so a stop signal can be received. No delay is
      // needed: the read above already waits while the port is idle.
      await Future.delayed(Duration.zero);
    }

    // Cleanup
    listener.cancel();
    receivePort.close();
    calloc.free(buffer);
  }
}

class _IsolateParams {
  final SendPort sendPort;
  final int portAddress;
  final int bufferSize;

  const _IsolateParams(this.sendPort, this.portAddress, this.bufferSize);
}

class _StopSignal {}
