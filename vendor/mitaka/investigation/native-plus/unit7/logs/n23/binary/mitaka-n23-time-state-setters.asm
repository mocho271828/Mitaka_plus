
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  485330: 0f be 44 24 04               	movsx	eax, byte ptr [esp + 0x4]
  485335: f2 0f 10 04 c5 60 06 d7 00   	movsd	xmm0, qword ptr [8*eax + 0xd70660]
  48533e: f2 0f 11 05 c0 90 fe 00      	movsd	qword ptr [0xfe90c0], xmm0
  485346: a2 60 0e d7 00               	mov	byte ptr [0xd70e60], al
  48534b: c3                           	ret
  48534c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  485350: f2 0f 10 44 24 04            	movsd	xmm0, qword ptr [esp + 0x4]
  485356: f2 0f 11 05 c0 90 fe 00      	movsd	qword ptr [0xfe90c0], xmm0
  48535e: c6 05 60 0e d7 00 0b         	mov	byte ptr [0xd70e60], 0xb
  485365: c3                           	ret
  485366: 8d 76 00                     	lea	esi, [esi]
  485369: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  485370: e8 3b b1 0d 00               	call	0x5604b0 <.text+0x15f4b0>
  485375: 50                           	push	eax
  485376: ff 74 24 08                  	push	dword ptr [esp + 0x8]
  48537a: e8 b1 60 01 00               	call	0x49b430 <.text+0x9a430>
  48537f: 83 c4 08                     	add	esp, 0x8
  485382: c3                           	ret
  485383: 8d b6 00 00 00 00            	lea	esi, [esi]
  485389: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  485390: 55                           	push	ebp
  485391: 8b ec                        	mov	ebp, esp
  485393: 83 e4 c0                     	and	esp, -0x40
  485396: 81 ec c0 00 00 00            	sub	esp, 0xc0
  48539c: f3 0f 5a 3d e4 90 fe 00      	cvtss2sd	xmm7, dword ptr [0xfe90e4]
  4853a4: 0f be 45 08                  	movsx	eax, byte ptr [ebp + 0x8]
  4853a8: f2 0f 10 35 e0 bc c2 00      	movsd	xmm6, qword ptr [0xc2bce0]
