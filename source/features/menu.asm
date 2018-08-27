; ==================================================================
; DaveDOS -- MikeOS with DaveDOS modifications
; Copyright (C) 2018 David Wilson
;
; The code here is predominately taken from kernel.asm and provides
; a system call to launch the menu interface. Previosuly this was
; just jumped to within the kernel. This allows us to call it from
; the command line.
;
; Copyright for code transplanted here from kernel.asm:
;
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2014 MikeOS Developers -- see doc/LICENSE.TXT
;
; MENU INTERFACE
;
; ==================================================================

os_launch_menu:
  pusha

	mov ax, os_init_msg		; Draw main screen layout
	mov bx, os_version_msg
	mov cx, 10011111b		; Colour: white text on light blue
	call os_draw_background

	call os_file_selector		; Get user to select a file, and store
					; the resulting string location in AX
					; (other registers are undetermined)

	jc start_command_line		; Return to the CLI/menu choice screen if Esc pressed

	mov si, ax			; Did the user try to run 'KERNEL.BIN'?
	mov di, kern_file_name
	call os_string_compare
	jc no_kernel_execute		; Show an error message if so


	; Next, we need to check that the program we're attempting to run is
	; valid -- in other words, that it has a .BIN extension

	push si				; Save filename temporarily

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, bin_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'BIN'?
	jne not_bin_extension		; If not, it might be a '.BAS'

	pop si				; Restore filename


	mov ax, si
	mov cx, 32768			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX


execute_bin_program:
	call os_clear_screen		; Clear screen before running

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov si, 0
	mov di, 0

	call 32768			; Call the external program code,
					; loaded at second 32K of segment
					; (program must end with 'ret')

	call os_clear_screen		; When finished, clear screen
	jmp os_launch_menu		; and go back to the program list


no_kernel_execute:			; Warn about trying to executing kernel!
	mov ax, kerndlg_string_1
	mov bx, kerndlg_string_2
	mov cx, kerndlg_string_3
	mov dx, 0			; One button for dialog box
	call os_dialog_box

	jmp os_launch_menu		; Start over again...


not_bin_extension:
	pop si				; We pushed during the .BIN extension check

	push si				; Save it again in case of error...

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, bas_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'BAS'?
	jne not_bas_extension		; If not, error out


	pop si

	mov ax, si
	mov cx, 32768			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	call os_clear_screen		; Clear screen before running

	mov ax, 32768
	mov si, 0			; No params to pass
	call os_run_basic		; And run our BASIC interpreter on the code!

	mov si, basic_finished_msg
	call os_print_string
	call os_wait_for_key

	call os_clear_screen
	jmp os_launch_menu		; and go back to the program list


not_bas_extension:
	pop si

	mov ax, ext_string_1
	mov bx, ext_string_2
	mov cx, 0
	mov dx, 0			; One button for dialog box
	call os_dialog_box

	jmp os_launch_menu		; Start over again...


	; And now data for the above code...

	kern_file_name		db 'KERNEL.BIN', 0

	autorun_bin_file_name	db 'AUTORUN.BIN', 0
	autorun_bas_file_name	db 'AUTORUN.BAS', 0

	bin_ext			db 'BIN'
	bas_ext			db 'BAS'

	kerndlg_string_1	db 'Cannot load and execute MikeOS kernel!', 0
	kerndlg_string_2	db 'KERNEL.BIN is the core of MikeOS, and', 0
	kerndlg_string_3	db 'is not a normal program.', 0

	ext_string_1		db 'Invalid filename extension! You can', 0
	ext_string_2		db 'only execute .BIN or .BAS programs.', 0

	basic_finished_msg	db '>>> BASIC program finished -- press a key', 0

	os_init_msg		db 'Welcome to MikeOS', 0
	os_version_msg		db 'Version ', MIKEOS_VER, 0

  popa
  ret

  .hi_there db 'Hi there!', 10, 13, 0
