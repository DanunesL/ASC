;fc58257

SECTION .data
errorMsg    db 'Número errado de parametros', 10, 0

SECTION .bss
message         resb 1024
messageNew      resb 1024
messageSize     resd 1
messageName     resb 255
rotations       resb 1
imageName       resb 255
imageModName    resb 255
imageSize       resd 1
imageOffset     resd 1
imageBytes      resd 1048576

SECTION .text
default rel

Extern readMessageFile 
Extern readImageFile  
Extern writeImageFile
Extern printStr
Extern terminate

global _start
_start:

    mov rax, [rsp]     ;Move a quantidade de parametros para rax
    cmp rax, 5         ;Compara com 5 (./Esconder 0 image.bmp image_mod.bmp) e se for diferente pula para o final do código onde será posta uma mensagem de erro
    jne paramError
    
    xor rax, rax
    
    mov rsi, [rsp + 16]     ;Pega o segundo parâmetro, no qual está o nome do arquivo da mensagem
    
ciclo_readMessageName:       ;Ciclo que irá ler cada caracter e o guardar na variável messageName
    mov al, [rsi + rcx]
    inc rcx
    mov [messageName + rbx], al
    inc rbx
    mov al, [rsi + rcx]
    cmp al, 0
    jne ciclo_readMessageName
    
    xor rdi, rdi
    xor rsi, rsi
    xor rbx, rbx
    xor rcx, rcx

   ;Aceder a mensagem atraves do nome e do tamanho máximo e retorna o tamamnho por eax
    mov rsi, message
    mov rdi, messageName
    call readMessageFile    
    mov [messageSize], eax  ;guardo o tamanho da mensagem na variável
    
    xor rax, rax
    xor rsi, rsi
    xor rdi, rdi
    
    
getRotations:
    mov rax, [rsp + 24]      ;Pega o terceiro parâmetro, no qual está o número de rotações
    mov rbx, [rax]           ;Passa para outro registo
    and bl, 0xCF             ;Utiliza a máscara 0xCF para transformar o valor ascii em um inteiro
    mov [rotations], bl      ;Guarda na variável
    
    
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
    
    mov rsi, [rsp + 32]  ;Pega o quarto parâmetro, no qual está o nome do arquivo da imagem não modificada
    
ciclo_readImageName:     ;Ciclo que irá ler cada caracter e o guardar na variável imageName
    mov al, [rsi + rcx]
    inc rcx
    mov [imageName + rbx], al
    inc rbx
    mov al, [rsi + rcx]
    cmp al, 0
    jne ciclo_readImageName
    
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
    
   ;Aceder ao arquivo da imagem através do nome e um buffer  
    mov rsi, imageBytes
    mov rdi, imageName      
    call readImageFile           
    mov [imageSize], rax  ;Retira o tamanho da imagem
    
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx
    xor rsi, rsi
    xor rdi, rdi 
    
    mov rsi, [rsp + 40]   ;Pega o quarto parâmetro, no qual está o nome da imagem modificada que irá ser criada
    
    
ciclo_readImageModName:   ;Ciclo que irá ler cada caracter e o guardar na variável imageModName
    mov al, [rsi + rcx]
    inc rcx
    mov [imageModName + rbx], al
    inc rbx
    mov al, [rsi + rcx]
    cmp al, 0
    jne ciclo_readImageModName
    
    xor rax, rax
    
   ;Pego o inicio do Offset da imagem e o guardo na variável 
    mov eax, [imageBytes + 10]  
    mov [imageOffset], eax
    
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdi, rdi
    xor rsi, rsi
    xor rdx, rdx
    xor r8, r8
    
   ;Pego o tamanho da mensagem e o somo 1 para depois verificar quando que está termina
    mov r10b, [messageSize]
    add r10, 1
    
    mov cl, [rotations] ;Move para cl a quantidade de rotations

    
ciclo_criptoMessage:    ;Ciclo que cria uma nova mensagem criptografada a partir da original, guardando na variável messageNew
    mov al, [message + rbx]
    ror al, cl
    mov [messageNew + rbx], al
    inc rbx
    cmp rbx, r10        ;quando rbx for igual ao r10 (messageSize + 1) quer dizer que ja passou todos os caracteres no vetor 
    jne ciclo_criptoMessage
    
    xor rsi, rsi
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor r8,r8
    
    mov esi, [imageOffset] ;Move para esi o inicio do offset da imagem

ciclo_HideMessage:      ;Ciclo que irá esconder a nova mensagem na imagem
    mov dl, [messageNew + rbx]
    inc rbx
    mov cl, 10000000b
    mov r8b, 7

ciclo_HideBit: ;Ciclo que irá esconder os bits no menos signifcativo dos bytes azul e vermelho
    
    mov r9b, dl                                ;Guarda o caracter em r9
    and r9b, cl                                ;Máscara do cl para pegar exatamente 1 bit
    push rcx                                   ;Salvaguardar a máscara
    mov cl, r8b                                ;Retirar o numero de rotações para que o bit chegue ao menos significativo
    shr r9b, cl                                ;Empurrar o bit para o máximo a direita (menos significativo)
    mov r8b, cl                                ;Mover de volta o valor das deslocações para o registo r8b (preucação)
    pop rcx                                    ;Recuperar a máscara
    shr cl, 1                                  ;Empurrar a máscara um para a esquerda, assim quando inciar o ciclo retirar o próximo bit
    dec r8b                                    ;Como esta 1 bit mais perto do menos significativo, diminuir o número de deslocações
    mov al, [imageBytes + rsi + rdi*2]         ;Aceder os bytes da imagem
    and al, 0xFE                               ;Máscara para zerar o menos significativo
    add al, r9b                                ;Adicionar um bit do caracter no bit menos significativo do byte da imagem
    mov [imageBytes + rsi + rdi*2], al         ;Retornar o valor do byte
    inc rdi                                    ;increase no rdi para pegar o pŕoximo byte (de 2 em 2)
    cmp cl, 0                                  ;Se a máscara estiver a 0 quer dizer que o caracter foi completamente escondido
    jne ciclo_HideBit                          ;Pula se a máscara não estiver a 0, ou seja ainda não terminou de esconder o caractér
    
    
    cmp rbx, r10                               ;quando rbx for igual ao r10 (messageSize + 1) quer dizer que ja passou todos os caracteres no vetor
    jne ciclo_HideMessage
     
fim:
    
    xor rdx, rdx
    xor rdi, rdi
    xor rsi, rsi
    
   ;Cria a imagem modificada com a mensagem escondida
    mov rdi, imageModName
    mov rsi, imageBytes
    mov rdx, [imageSize]
    call writeImageFile
    
    call terminate
    
paramError:             ;Se tiver o número de parâmetros errados, da print de uma mensagem de erro e termina a execução
    mov rdi, errorMsg
    call printStr
    call terminate