include '..\FASM\INCLUDE\win32ax.inc'

.data 
	c_file_name	dd 0x0
	c_file_rnd_name: times 8 db 0x0
				 db '.tmp',0
	c_file_handle	dd 0x0
	c_file_size	dd 0x0
	c_map_handle	dd 0x0
	c_map_pointer	dd 0x0

	compain_name	db 'start.bat',0
	compain_data	dd 0x0
	compain_pointer dd 0x0
	compain_start	db 'copy '
	compain_handle	dd 0x0

	split_handle	dd 0x0
	split_counter	db 0x0

	rand_name_buffer: times 8 db 0x0
	rnd_file_name: times 8 db 0x0
			       db '.tmp',0
	ZERO_field	dd 0x0

systemtime_struct:	   
	  dw 0		       
	  dw 0		       
	  dw 0		        
	  dw 0		        
	  dw 0		        
	  dw 0		        
	  dw 0		        
rnd:	  dw 0		   

.code
   start:
	invoke	GetCommandLine
	inc	eax			 

	mov	ebx, eax			

    get_my_name:
	inc	ebx				
	cmp	byte [ebx], '.' 		
    jne get_my_name

	mov	byte [ebx+4], 0x0		
	mov	[c_file_name], eax		

	invoke	DeleteFile, compain_name		

	mov	ebp, 0xAAAAAAAA 		
	call	random_name			

	mov	esi, rnd_file_name		
	mov	edi, c_file_rnd_name	
	mov	ecx, 8				
	rep	movsb				

	invoke	CopyFile, [c_file_name], c_file_rnd_name, FALSE    	

	invoke	CreateFile, c_file_rnd_name, GENERIC_READ or GENERIC_WRITE, 0x0, 0x0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0x0 	  	
	mov	[c_file_handle], eax							  	

	invoke	GetFileSize, [c_file_handle], c_file_size				  	
	mov	[c_file_size], eax							  	

	invoke	CreateFileMapping, [c_file_handle], 0x0, PAGE_READWRITE, 0x0, [c_file_size], 0x0    	
	mov	[c_map_handle], eax								    	

	invoke	MapViewOfFile, [c_map_handle], FILE_MAP_WRITE, 0x0, 0x0, [c_file_size]		  
	mov	[c_map_pointer], eax								

	invoke	VirtualAlloc, 0x0, 0x120000, 0x1000, 0x4	; Reserve Space in Memory
	mov	[compain_data], eax				
	mov	[compain_pointer], eax				

	mov	esi, compain_start				
	mov	edi, [compain_pointer]				
	mov	ecx, 5						
	rep	movsb						

	add	[compain_pointer], 5				

    main_loop:
	mov	ebp, 0xAAAAAAAA 		
	call	random_name			

	invoke	CreateFile, rnd_file_name, GENERIC_READ or GENERIC_WRITE, 0x0, 0x0, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0x0
	cmp	eax, INVALID_HANDLE_VALUE		; If file already existed
	je	main_loop				

	mov	[split_handle], eax		
	call	random_number		
	xor	eax, eax				; eax=0
	mov	al, [rand_name_buffer]			; al~=random
	and	al, 7					; al= 0000 0???
	add	al, 3					; At least three byte
	mov	[split_counter], al			; Save that bytes

	sub	[c_file_size], eax			; Decrease the bytes to write

	invoke	WriteFile, [split_handle], [c_map_pointer], eax, ZERO_field, 0x0       ; Write (1..8) byte
	invoke	CloseHandle, [split_handle]		; Close the file

	xor	eax, eax
	mov	al, [split_counter]			; How many bytes written
	add	[c_map_pointer], eax			; Add the pointer - write the next few bytes next time

	mov	esi, rnd_file_name			; From: Filename-buffer
	mov	edi, [compain_pointer]			; To: compainer-pointer
	mov	ecx, 12 				; 8+strlen('.tmp')
	rep	movsb					; Write!

	add	[compain_pointer], 12			; Add 12 to pointer

	mov	eax, [compain_pointer]			; Pointer to eax

	mov	byte [eax], '+' 			; Move '+' to the code's memory
	inc	[compain_pointer]			; Increase the pointer

	cmp	[c_file_size], 0			; Compare if more bytes to write
    jg	main_loop					; If yes, jmp to main_loop

	invoke	UnmapViewOfFile, [c_map_pointer]	; Unmap View of File
	invoke	CloseHandle, [c_map_handle]		; Close Map
	invoke	CloseHandle, [c_file_handle]		; Close File

	invoke	DeleteFile, c_file_rnd_name		; Delete the temporary copy of the current file

	invoke	CreateFile, compain_name, GENERIC_READ or GENERIC_WRITE, 0x0, 0x0, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0x0
	mov	[compain_handle], eax


	mov	eax, [compain_pointer]		; eax=pointer
	dec	eax				; Delete the last '+'
	mov	byte [eax], 0x20		; Add a space
	inc	[compain_pointer]		; Increase pointer again

	mov	ebp, 0xAAAAAAAA 		; Influences the random engine
	call	random_name			; random name in rnd_file_name

	mov	eax, rnd_file_name		; RND-pointer in eax
	add	eax, 8				; add 8 to pointer (='.' of filename)
	mov	dword [eax], '.exe'		; instate of '.tmp', '.exe'

	dec	[compain_pointer]
	mov	esi, rnd_file_name		; From: rnd_file_name
	mov	edi, [compain_pointer]		; To: compainter_pointer
	mov	ecx, 12 			; How much: 12 bytes
	rep	movsb				; Write

	add	[compain_pointer], 12		; Add 12, to get the end again
	mov	eax, [compain_pointer]		; eax=pointer to content
	mov	word [eax], 0x0A0D		; Next Line
	add	[compain_pointer], 2

	mov	esi, rnd_file_name		; From: rnd_file_name
	mov	edi, [compain_pointer]		; To: compainter_pointer
	mov	ecx, 12 			; How much: 12 bytes
	rep	movsb				; Write

	add	[compain_pointer], 12		; Add 12, to get the end again


	mov	eax, [compain_data]
	sub	[compain_pointer], eax

	invoke	WriteFile, [compain_handle], [compain_data], [compain_pointer], ZERO_field, 0x0       ; Write the file

	invoke	CloseHandle, [compain_handle]

	invoke	ExitProcess, 0x0

random_number:
	pop	edi		
	push	edi				
	mov	ecx, 8				
	mov	dh, 0xAA		
	mov	dl, 0x87		
   random_name_loop:
	push	dx			
	push	ecx	
	call	random_byte	
	pop	ecx				
	xor	al, cl			
	pop	dx				
	push	ecx
	xor	dx, cx			
	add	dh, al			
	sub	dl, al			
	neg	dl				
	xor	dl, dh		
	xor	al, dl		
	sub	ax, di		
	add	ax, dx		
	mov	dl, [rand_name_buffer+ecx-2]
	mov	dh, [rand_name_buffer+ecx-3]	
	sub	al, dl			
	add	al, dh			
	mov	ah, dl			
	push	ax			
	mov	cl, 1			
	or	dh, cl			
	mul	dh				
	pop	cx				
	push	cx			
	add	cl, al			
	sub	cl, ah		
	xchg	al, cl	
	mov	cx, bp		
	mul	cl			
	neg	ah			
	xor	al, ah		
	pop	cx			
	sub	cl, al				
	add	cl, dl				
	sub	al, cl			
	pop	ecx				
	mov	[rand_name_buffer+ecx-1], al	; Save random letter
   loop random_name_loop
ret



random_name:
	call	random_number	
	mov	ecx, 8				

   changetoletter:
	mov	al, [rand_name_buffer+ecx-1]	
	mov	bl, 10				; BL=10
	xor	ah, ah				; AX: 0000 0000 ???? ????
	div	bl				; AL=rnd/10=number between 0 and 25
	add	al, 97				; Add 97 for getting lowercase letters
	mov	[rnd_file_name+ecx-1], al	
   loop changetoletter
ret

random_byte:
	invoke	GetSystemTime, systemtime_struct	
	mov	ebx, [rnd-2]			
	add	ebx, edx				
	sub	ebx, ecx
	xor	ebx, eax
	xchg	bl, bh
	pop	ecx
	push	ecx
	neg	ebx
	xor	ebx, ecx				

	invoke	GetTickCount		
	xor	eax, ecx	
	neg	ax			
	xor	eax, edx
	xor	ah, al
	sub	eax, ebp
	add	eax, esi	

	xor	eax, ebx	
	mov	ebx, eax	
	shr	eax, 8		
	xor	ax, bx
	xor	al, ah			
ret
.end start           
