
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Fuentes base (equivalente a CS.fDisplay, CS.fBody, CS.fMono)
  static TextStyle get display => GoogleFonts.spaceGrotesk();
  static TextStyle get body    => GoogleFonts.manrope();
  static TextStyle get mono    => GoogleFonts.jetBrainsMono();

  // .cs-h1
  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w600,
    fontSize: 28,
    letterSpacing: -0.7,
    height: 1.05,
    color: AppColors.text,
  );

  // .cs-h2
  static TextStyle get h2 => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w600,
    fontSize: 22,
    letterSpacing: -0.44,
    height: 1.1,
    color: AppColors.text,
  );

  // .cs-h3
  static TextStyle get h3 => GoogleFonts.spaceGrotesk(
    fontWeight: FontWeight.w500,
    fontSize: 17,
    letterSpacing: -0.26,
    height: 1.2,
    color: AppColors.text,
  );

  // .cs-eyebrow (el texto pequeño en mayúsculas tipo "EN PROYECCIÓN")
  static TextStyle get eyebrow => GoogleFonts.jetBrainsMono(
    fontWeight: FontWeight.w500,
    fontSize: 10,
    letterSpacing: 1.8,
    color: AppColors.textDim,
  );

  // .cs-mono
  static TextStyle get monoBase => GoogleFonts.jetBrainsMono(
    letterSpacing: -0.1,
    color: AppColors.text,
  );

  // Cuerpo normal
  static TextStyle get bodyBase => GoogleFonts.manrope(
    fontSize: 15,
    letterSpacing: -0.15,
    color: AppColors.text,
  );

  // Cuerpo secundario (textDim)
  static TextStyle get bodyDim => GoogleFonts.manrope(
    fontSize: 13,
    letterSpacing: -0.13,
    color: AppColors.textDim,
    height: 1.5,
  );

  // Botón
  static TextStyle get button => GoogleFonts.manrope(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    letterSpacing: -0.15,
    color: Colors.white,
  );
}