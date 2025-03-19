import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';

class Helpers {
  // Format currency
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  // Format date
  static String formatDate(DateTime date, {bool showTime = false}) {
    if (showTime) {
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Create a temporary file from a URL
  static Future<File> urlToFile(String imageUrl) async {
    // Get temporary directory
    final dir = await getTemporaryDirectory();

    // Generate a unique filename
    final filename = '${DateTime.now().millisecondsSinceEpoch}.png';
    final path = '${dir.path}/$filename';

    // Download file
    final response = await NetworkAssetBundle(Uri.parse(imageUrl))
        .load(imageUrl);
    final bytes = response.buffer.asUint8List();

    // Save to temporary file
    return File(path)..writeAsBytes(bytes);
  }

  // Launch URL
  static Future<bool> launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Show custom snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Calculate size comparison
  static Map<String, dynamic> compareSizes(Map<String, dynamic> productDimensions, double measuredDimension) {
    // Get product dimensions
    final width = productDimensions['width'] as double? ?? 0;
    final height = productDimensions['height'] as double? ?? 0;
    final depth = productDimensions['depth'] as double? ?? 0;

    // Compare with measured dimension
    final widthDiff = measuredDimension - width;
    final heightDiff = measuredDimension - height;
    final depthDiff = measuredDimension - depth;

    // Find the closest dimension
    if (widthDiff.abs() <= heightDiff.abs() && widthDiff.abs() <= depthDiff.abs()) {
      return {
        'dimension': 'width',
        'difference': widthDiff,
        'fits': widthDiff >= 0,
      };
    } else if (heightDiff.abs() <= depthDiff.abs()) {
      return {
        'dimension': 'height',
        'difference': heightDiff,
        'fits': heightDiff >= 0,
      };
    } else {
      return {
        'dimension': 'depth',
        'difference': depthDiff,
        'fits': depthDiff >= 0,
      };
    }
  }

  // Generate a unique ID
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}