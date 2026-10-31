import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class HomeZodiacWidget extends StatelessWidget {
  const HomeZodiacWidget({Key? key}) : super(key: key);

  final List<Map<String, String>> _zodiacs = const [
    {'name': 'Aries', 'dates': 'Mar 21-Apr 19', 'symbol': '♈'},
    {'name': 'Taurus', 'dates': 'Apr 20-May 20', 'symbol': '♉'},
    {'name': 'Gemini', 'dates': 'May 21-Jun 20', 'symbol': '♊'},
    {'name': 'Cancer', 'dates': 'Jun 21-Jul 22', 'symbol': '♋'},
    {'name': 'Leo', 'dates': 'Jul 23-Aug 22', 'symbol': '♌'},
    {'name': 'Virgo', 'dates': 'Aug 23-Sep 22', 'symbol': '♍'},
    {'name': 'Libra', 'dates': 'Sep 23-Oct 22', 'symbol': '♎'},
    {'name': 'Scorpio', 'dates': 'Oct 23-Nov 21', 'symbol': '♏'},
    {'name': 'Sagittarius', 'dates': 'Nov 22-Dec 21', 'symbol': '♐'},
    {'name': 'Capricorn', 'dates': 'Dec 22-Jan 19', 'symbol': '♑'},
    {'name': 'Aquarius', 'dates': 'Jan 20-Feb 18', 'symbol': '♒'},
    {'name': 'Pisces', 'dates': 'Feb 19-Mar 20', 'symbol': '♓'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Daily Horoscopes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
            ),
            Text(
              "Select Your Sign",
              style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _zodiacs.length,
            itemBuilder: (ctx, idx) {
              final z = _zodiacs[idx];
              return Container(
                width: 75,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkCard,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      z['symbol']!,
                      style: const TextStyle(fontSize: 24, color: AppColors.accentGold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      z['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimaryDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
