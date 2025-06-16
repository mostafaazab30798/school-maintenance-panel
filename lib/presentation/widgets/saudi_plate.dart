import 'package:flutter/material.dart';

class SaudiLicensePlate extends StatelessWidget {
  final String englishNumbers;
  final String arabicLetters;
  final String englishLetters;
  final bool isHorizontal;

  const SaudiLicensePlate({
    Key? key,
    this.englishNumbers = '7356',
    this.arabicLetters = 'ج ن ط',
    this.englishLetters = 'T N J',
    this.isHorizontal = false,
  }) : super(key: key);

  String _translateToArabicNumbers(String englishNumbers) {
    const Map<String, String> numberMap = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };

    String result = '';
    for (int i = 0; i < englishNumbers.length; i++) {
      String char = englishNumbers[i];
      result += numberMap[char] ?? char;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    String arabicNumbers = _translateToArabicNumbers(englishNumbers);
    final theme = Theme.of(context);

    if (isHorizontal) {
      return Container(
        width: 320,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left section - Arabic letters
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  border:
                      Border(right: BorderSide(color: Colors.black, width: 2)),
                ),
                child: Column(
                  children: [
                    // Top part - Arabic letters
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(color: Colors.black, width: 2)),
                        ),
                        child: Center(
                          child: Text(
                            arabicLetters,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                              letterSpacing: 3,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ),
                    // Bottom part - English letters
                    Expanded(
                      child: Center(
                        child: Text(
                          englishLetters,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Middle section - KSA emblem
            Container(
              width: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5), // Blue background
                border:
                    Border(right: BorderSide(color: Colors.black, width: 2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Saudi emblem (simplified representation)
                  Image.asset(
                    'assets/images/ksa_logo.png',
                    height: 40,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 4),
                  // KSA text
                  Text(
                    'KSA',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Right section - Numbers
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Top part - Arabic numbers
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.black, width: 2)),
                      ),
                      child: Center(
                        child: Text(
                          arabicNumbers,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                  // Bottom part - English numbers
                  Expanded(
                    child: Center(
                      child: Text(
                        englishNumbers,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Original vertical layout
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left section - Arabic numbers
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Column(
                children: [
                  // Top part - Arabic numbers
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          arabicNumbers,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                  // Bottom part - English numbers
                  Expanded(
                    child: Center(
                      child: Text(
                        englishNumbers,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Middle section - KSA emblem
          Container(
            width: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5), // Blue background
              border: Border(
                right: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Saudi emblem (simplified representation)
                Image.asset(
                  'assets/images/ksa_logo.png',
                  // width: AppSizes.blockWidth * 5,
                  height: 50,
                  color: Colors.black,
                ),
                const SizedBox(height: 5),
                // KSA text
                Text(
                  'KSA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                // Small icons/symbols
              ],
            ),
          ),
          // Right section - Arabic letters
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Top part - Arabic letters
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        arabicLetters,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 20,
                          color: Colors.black,
                          letterSpacing: 3,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ),
                // Bottom part - English letters
                Expanded(
                  child: Center(
                    child: Text(
                      englishLetters,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 20,
                        color: Colors.black,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
