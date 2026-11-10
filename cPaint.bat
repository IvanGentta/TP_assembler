@echo off
tasm main.asm
tasm interfaz.asm
tasm libPaint.asm
tlink main + libPaint + interfaz
main
