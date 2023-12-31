import 'package:flutter/material.dart';

/// A simple card with a large title and optional subtitle, plus a > arrow to indicate a submenu.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, this.text, this.subText, this.onTap, this.content})
      : assert((text == null) ^ (content == null));

  final String? text;
  final String? subText;
  final Widget? content;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 2, top: 5, bottom: 5),
          child: Row(
            children: [
              Expanded(
                child: content ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (subText != null)
                          Text(
                            subText!,
                          ),
                      ],
                    ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
