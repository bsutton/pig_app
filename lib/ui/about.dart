import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import to handle URL launching

import '../src/version/version.g.dart';
import '../util/app_title.dart';
import '../util/exceptions.dart';
import 'widgets/hmb_button.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    setAppTitle('About/Support');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(automaticallyImplyLeading: false),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('PiGation'),
          Text('Version: $packageVersion'),
          const Text('Author: S. Brett Sutton'),
          const SizedBox(height: 20),
          const Text(
            'Get Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...linkButton(
            description: 'Read the manual and getting started guide',
            label: 'Manual/Getting Started',
            link: 'https://hmb.onepub.dev',
          ),
          ...linkButton(
            description: 'Have a problem; raise issues',
            label: 'GitHub Repository',
            link: 'https://github.com/bsutton/pigation2',
          ),
          ...linkButton(
            description: 'Feel free to start a discussion:',
            label: 'Discussions',
            link: 'https://github.com/bsutton/hmb/discussions',
          ),
        ],
      ),
    ),
  );

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw IrrigationAppException('Could not launch $url');
    }
  }

  List<Widget> linkButton({
    required String description,
    required String label,
    required String link,
  }) => [
    Text(description, textAlign: TextAlign.center),
    HMBLinkButton(onPressed: () => _launchURL(link), label: label, link: link),
  ];
}
