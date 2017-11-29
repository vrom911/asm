asm : 
	@nasm -f elf64 -o task.o task.asm 
	@ld -o task task.o 
	@./task
