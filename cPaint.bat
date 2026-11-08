@echo off
tasm main.asm
tasm libPaint.asm
tlink main + libPaint
main