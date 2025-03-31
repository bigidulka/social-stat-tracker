import 'package:flutter/material.dart';

class AppStyle {
  // Цвета
  static const Color primaryColor = Color(0xFF3B82F6); // Светло-синий
  static const Color accentColor = Color(0xFFF97316);  // Оранжевый
  static const Color backgroundColor = Color(0xFFF4F4F5); // Светлый фон
  static const Color textColor = Colors.black87;
  static const Color subtitleColor = Colors.black54;
  static const Color borderColor = Colors.grey;
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Colors.green;

  // Общие отступы
  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  // Заголовки и текст
  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: subtitleColor,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle linkTextStyle = TextStyle(
    fontSize: 14,
    color: primaryColor,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle errorTextStyle = TextStyle(
    color: errorColor,
    fontSize: 14,
  );

  // Поля ввода
  static final inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    labelStyle: TextStyle(color: textColor),
    hintStyle: TextStyle(color: Colors.grey),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // Основная кнопка
  static final buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    textStyle: buttonTextStyle,
  );

  // Вторичная кнопка
  static final secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: BorderSide(color: primaryColor),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  );

  // Текстовая кнопка
  static final textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  );

  // Карточка
  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  );

  // Кастомная тень
  static final BoxShadow defaultShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 6,
    offset: Offset(0, 3),
  );

  // Лоадер
  static const Widget loader = Center(child: CircularProgressIndicator());
}
