@echo off
tasm paintm.asm
tasm interfaz.asm
tlink paintm + interfaz
paintm