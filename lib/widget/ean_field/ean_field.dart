import 'package:Blackout/generated/l10n.dart';
import 'package:Blackout/main.dart';
import 'package:Blackout/widget/checkable/checkable.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void EanCallback(String value, bool error);

class EanField extends StatefulWidget {
  final String initialEan;
  final EanCallback callback;

  EanField({Key key, this.initialEan, this.callback}) : super(key: key);

  @override
  _EanFieldState createState() => _EanFieldState();
}

class _EanFieldState extends State<EanField> {
  TextEditingController _controller;
  bool _checked;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _checked = widget.initialEan != null;
    _controller = TextEditingController(text: widget.initialEan);
    _controller.addListener(() {
      invokeCallback();
    });
  }

  void invokeCallback() {
    if (_checked && _controller.text == "") {
      setState(() {
        _error = true;
      });
    } else {
      setState(() {
        _error = false;
      });
    }
    widget.callback(_checked ? _controller.text : null, _error);
  }

  @override
  Widget build(BuildContext context) {
    return Checkable(
      initialChecked: _checked,
      checkedCallback: (context) => Expanded(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.center_focus_weak),
              onPressed: _checked
                  ? () async {
                      if (isEmulator) {
                        _controller.text = "someEan";
                      } else {
                        var options = ScanOptions(restrictFormat: [BarcodeFormat.ean8, BarcodeFormat.ean13]);
                        var result = await BarcodeScanner.scan(options: options);
                        _controller.text = result.rawContent;
                      }
                      invokeCallback();
                    }
                  : null,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: S.of(context).ean,
                  errorText: _error ? "Must not be empty" : null,
                ),
              ),
            )
          ],
        ),
      ),
      uncheckedCallback: (context) => Expanded(
        child: Text(
          S.of(context).ean,
          textAlign: TextAlign.center,
        ),
      ),
      callback: (checked) {
        setState(() {
          _checked = checked;
        });
        invokeCallback();
      },
    );
  }
}