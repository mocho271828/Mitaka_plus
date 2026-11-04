
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  54dfb0: c2 00 68                     	ret	0x6800
  54dfb3: 03 03                        	add	eax, dword ptr [ebx]
  54dfb5: 00 00                        	add	byte ptr [eax], al
  54dfb7: 68 02 03 00 00               	push	0x302
  54dfbc: ff 15 78 59 c2 00            	call	dword ptr [0xc25978]
  54dfc2: 6a 01                        	push	0x1
  54dfc4: ff 15 c8 59 c2 00            	call	dword ptr [0xc259c8]
  54dfca: 0f be 05 28 1e d7 00         	movsx	eax, byte ptr [0xd71e28]
  54dfd1: a8 03                        	test	al, 0x3
  54dfd3: 74 47                        	je	0x54e01c <.text+0x14d01c>
  54dfd5: 68 c0 d5 c2 00               	push	0xc2d5c0
  54dfda: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  54dfdf: e8 3c fb fe ff               	call	0x53db20 <.text+0x13cb20>
  54dfe4: 89 85 ec fe ff ff            	mov	dword ptr [ebp - 0x114], eax
  54dfea: 68 f0 e1 c2 00               	push	0xc2e1f0
  54dfef: b9 60 74 10 01               	mov	ecx, 0x1107460
  54dff4: e8 e7 d6 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  54dff9: 8b 95 ec fe ff ff            	mov	edx, dword ptr [ebp - 0x114]
  54dfff: 83 c4 f4                     	add	esp, -0xc
  54e002: 89 3c 24                     	mov	dword ptr [esp], edi
  54e005: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  54e009: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  54e00d: e8 ae 4b ff ff               	call	0x542bc0 <.text+0x141bc0>
  54e012: 83 c4 0c                     	add	esp, 0xc
  54e015: 0f be 05 28 1e d7 00         	movsx	eax, byte ptr [0xd71e28]
  54e01c: a8 0c                        	test	al, 0xc
  54e01e: 74 40                        	je	0x54e060 <.text+0x14d060>
  54e020: 68 c0 d5 c2 00               	push	0xc2d5c0
  54e025: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  54e02a: e8 f1 fa fe ff               	call	0x53db20 <.text+0x13cb20>
  54e02f: 89 85 ec fe ff ff            	mov	dword ptr [ebp - 0x114], eax
  54e035: 68 f0 e1 c2 00               	push	0xc2e1f0
  54e03a: b9 60 74 10 01               	mov	ecx, 0x1107460
  54e03f: e8 9c d6 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  54e044: 8b 95 ec fe ff ff            	mov	edx, dword ptr [ebp - 0x114]
  54e04a: 83 c4 f4                     	add	esp, -0xc
  54e04d: 89 3c 24                     	mov	dword ptr [esp], edi
  54e050: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  54e054: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  54e058: e8 d3 4e ff ff               	call	0x542f30 <.text+0x141f30>
  54e05d: 83 c4 0c                     	add	esp, 0xc
  54e060: e8 6b c6 07 00               	call	0x5ca6d0 <.text+0x1c96d0>
  54e065: 8b c8                        	mov	ecx, eax
  54e067: e8 94 cf 07 00               	call	0x5cb000 <.text+0x1ca000>
  54e06c: 0f b6 c0                     	movzx	eax, al
  54e06f: 85 c0                        	test	eax, eax
