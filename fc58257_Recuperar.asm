;fc58257

Section .data
errorMsg    db 'Numero errado de parametros', 10, 0

Section .bss
rotations   resb 1
imageName   resb 255 
imageBytes  resd 1048576
imageSize   resb 1024
imageOffset resd 1
message     resb 1024

SECTION .text
default rel

Extern readImageFile
Extern printStr
Extern terminate

global _start
_start:

    mov rax, [rsp]     ;Move a quantidade de parametros para rax
    cmp rax, 3         ;Compara com 3 (./Recuperar 0 iamge_mod.bmp) e se for diferente pula para o final do código onde será posta uma mensagem de erro
    jne paramError
    
    xor rax, rax
    
getRotations: 

    mov rax, [rsp + 16]       ;Pega o segundo parâmetro, no qual está o número de rotações
    mov rbx, [rax]            ;Passa para outro registo
    and bl, 0xCF              ;Utiliza a máscara 0xCF para transformar o valor ascii em um inteiro 
    mov [rotations], bl       ;Guarda na variável
    
    xor rbx, rbx
    xor rax, rax
    
    mov rsi, [rsp + 24]        ;Pega o terceiro parâmetro, no qual está o nome da imagem
    
ciclo_readName:                ;Ciclo que irá ler cada caracter e o guardar na variável imageName
    mov al, [rsi + rcx]        
    inc rcx
    mov [imageName + rbx], al
    inc rbx
    mov al, [rsi + rcx]
    cmp al, 0
    jne ciclo_readName
    
   ;Aceder ao arquivo da imagem através do nome e um buffer                 
    mov rsi, imageBytes
    mov rdi, imageName      
    call readImageFile           
    mov [imageSize], rax  ;Retirar o tamanho da imagem
    
    xor rax, rax
  
   ;Guardar o inicio do Offset da imagem na variável imageOffset
    mov eax, [imageBytes + 10]  
    mov [imageOffset], eax
    
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
    xor rdx, rdx
    xor rdi, rdi
    xor rsi, rsi
    
    mov r11b, [imageSize]
    mov rdi, [imageOffset]
    
;Ciclo que irá pegar o último bit dos bytes azul e vermelho da imagem, andando em 2 em 2
ciclo_caracter:
    mov al, [imageBytes + rdi + rcx*2]
    inc rcx
    and al, 0x01                        ;Máscara para pegar o bit menos significativo 
    add dl, al                          ;adicionar esse bit a dl, que ira guardar o caracter inteiro
    cmp r8, 7                           ;Se r8 for 7 quer dizer que o caracter ja está completo
    jne build_caracter   
    jmp rotate_caracter                 ;Jump obrigatório para o ciclo de rotação (mesmo que rotations seja 0) 

;Ciclo que constrói um digito de 1 byte com os pegos na função anterior, e os empurra para a esquerda até 8 vezes
build_caracter:
    shl dl, 1                           ;Desloca para a esquerda para adicionar o proximo bit
    inc r8                              ;Increase em r8 para um contador
    jmp ciclo_caracter

;Após ter o caracter feito, é realizada a rotação dos bits
rotate_caracter:
    mov r10, rcx                        ;Salvaguarda rcx (contador do Offset) em r10 para utilizar em rotations
    mov cl, [rotations]         
    rol dl, cl                          ;Rotaciona o caracter
    mov rcx, r10                        ;Retorna o valor atual de rcx

;Por fim é guardado na variavel mensagem, antes dl é comparado com 0 para verificar se a frase ja acabou ou não, se for 0 é dado com terminada    
place_caracter:
    cmp dl, 0                           ;Se for 0, quer dizer que é nulo e que a mensagem acabou
    je fim
    mov [message + rbx], dl             ;Adiciona o caracter a variável mensagem
    inc rbx                             ;Increase em rbx, assim movendo para o próximo caracter
    
    xor r8, r8
    xor rdx, rdx
    jmp ciclo_caracter                  ;Após inserir o novo caracter em mensagem da um jump obrigatorio ao incio da leitura de caracteres
    
    
fim:    
    xor rdi, rdi
    xor rsi, rsi
   ;print da mensagem
    mov rdi, message 
    call printStr
   
   ;terminar 
    call terminate 
    
paramError:             ;Se tiver o número de parâmetros errados, da print de uma mensagem de erro e termina a execução
    mov rdi, errorMsg
    call printStr
    call terminate