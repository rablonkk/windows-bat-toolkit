# Windows BAT Toolkit: scripts .bat para correção e reparo de pc em geral.

[English](README.en.md) | **Português (BR)**

![Plataforma](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white)
![Linguagem](https://img.shields.io/badge/Batch-.bat-4D4D4D?logo=windowsterminal&logoColor=white)
![Licenca](https://img.shields.io/badge/licen%C3%A7a-MIT-green)
![Idioma](https://img.shields.io/badge/interface-PT--BR-blue)

Coleção de scripts em **Batch (.bat)** com menu interativo para **Windows 10 e 11**. Cada script resolve um problema específico e comum:

- **Sem internet, DNS que não resolve, IP que não renova:** diagnóstico e reparo de rede.
- **PC cheio de lixo temporário:** limpeza segura de Temp, cache do Windows Update e de navegadores.
- **Apps da Adobe que não desinstala direito:** remoção do Creative Cloud e dos resíduos.
- **Tela preta, travamentos e erros de placas de vídeo AMD:** limpeza de drivers para instalação do zero.

Este repositório é de código aberto, você pode (e deve) ler o guia completo antes de executar qualquer batch.

## Sumário

- [Os scripts](#os-scripts)
- [Como usar](#como-usar)
- [network-fix.bat: corrigir problemas de internet no Windows](#network-fixbat-corrigir-problemas-de-internet-no-windows)
- [clean-temp.bat: limpar arquivos temporários](#clean-tempbat-limpar-arquivos-temporários)
- [adobe-remover.bat: desinstalar a Adobe por completo](#adobe-removerbat-desinstalar-a-adobe-por-completo)
- [amd-driver-cleaner.bat: limpar drivers de vídeo AMD](#amd-driver-cleanerbat-limpar-drivers-de-vídeo-amd)
- [Segurança e transparência](#segurança-e-transparência)
- [Perguntas frequentes](#perguntas-frequentes)
- [Compatibilidade](#compatibilidade)
- [Créditos, contribuição e licença](#créditos-contribuição-e-licença)

## Os scripts

| Script | Para que serve | Exige admin | Altera registro |
|---|---|---|---|
| [`network-fix.bat`](scripts/network-fix.bat) | Diagnosticar e corrigir internet, DNS, IP, proxy e Winsock | Só nas correções | Sim (proxy, Winsock) |
| [`clean-temp.bat`](scripts/clean-temp.bat) | Liberar espaço limpando temporários e caches | Recomendado | Não |
| [`adobe-remover.bat`](scripts/adobe-remover.bat) | Desinstalar produtos Adobe e remover resíduos | Sim | Sim, com backup `.reg` |
| [`amd-driver-cleaner.bat`](scripts/amd-driver-cleaner.bat) | Remover drivers de vídeo AMD para reinstalação limpa | Sim | Sim, com backup `.reg` |

A interface dos menus está em **português do Brasil**.

## Como usar

1. Clique em **Code > Download ZIP** (ou baixe pela aba **Releases**) e extraia a pasta.
2. **Leia o script** que vai executar. Ele é texto puro, abra no Bloco de Notas.
3. Clique com o botão direito no `.bat` e escolha **Executar como administrador**.
4. Escolha uma opção no menu. Ações que apagam ou alteram algo pedem confirmação.

Se o Windows exibir "O Windows protegeu o computador" (SmartScreen), é o aviso padrão para qualquer script baixado da internet. Só prossiga em **Mais informações > Executar assim mesmo** se você leu o código e confia nele.

### Antes de qualquer limpeza pesada

Crie um ponto de restauração. Em **Painel de Controle > Sistema > Proteção do Sistema > Criar**. Isso vale principalmente para `adobe-remover.bat` e `amd-driver-cleaner.bat`.

---

## network-fix.bat: corrigir problemas de internet no Windows

**Quando usar:** o Wi-Fi ou a rede cabeada conecta, mas as páginas não abrem; erros como `DNS_PROBE_FINISHED_NO_INTERNET` ou `ERR_NAME_NOT_RESOLVED`; IP inválido; proxy que sobrou de algum programa.

**Ideia central:** separar a causa. O diagnóstico testa em camadas (IP, gateway, internet por IP, DNS), então você sabe se o problema é no PC, no roteador, no provedor ou só no DNS.

| Opção | O que faz |
|---|---|
| 1 | Mostra a configuração de IP (`ipconfig /all`) |
| 2 | Detecta o gateway (roteador) pela tabela de rotas e testa com ping |
| 3 | Testa a internet por IP (`1.1.1.1` e `8.8.8.8`) |
| 4 | Testa DNS com o resolvedor atual **e** com `1.1.1.1`. Se só o externo resolve, o DNS do roteador ou do provedor é o culpado |
| 5 | Lista adaptadores e mostra o estado do Wi-Fi |
| 6 | Mostra o proxy do WinHTTP **e** o do WinINET (o que os navegadores usam) |
| 7 | Executa o diagnóstico completo (1 a 6) |
| A | Limpa o cache DNS |
| B | Renova o IP (`release` e `renew`) |
| C | Reseta o proxy |
| D | Reinicia os adaptadores de rede físicos ativos |
| E | Reset de Winsock e da pilha TCP/IP (exige reiniciar o PC) |
| F | Correção automática: A, C, B, D e teste final |

**Cuidados:** B, D, E e parte de C exigem administrador. A opção E remove configuração de IP estático. A opção F derruba a conexão por alguns segundos.

---

## clean-temp.bat: limpar arquivos temporários

**Quando usar:** disco quase cheio, atualização do Windows que não baixa direito, pastas `Temp` enormes.

| Opção | O que limpa |
|---|---|
| 1 | Temp do usuário (`%TEMP%`, CrashDumps, relatórios de erro, INetCache) |
| 2 | Temp do sistema (`Windows\Temp`, relatórios de erro globais) |
| 3 | Cache de downloads do Windows Update (`SoftwareDistribution\Download`) |
| 4 | Cache de Chrome, Edge, Brave e Firefox (todos os perfis) |
| 5 | Lixeira (pede confirmação) |
| 6 | Limpeza segura: 1 + 2 + 3 + 4 |
| 7 | Componentes do Windows via `DISM /StartComponentCleanup` (lento) |

Ao final, mostra o espaço liberado no drive do sistema.

**O que ele propositalmente NÃO apaga:** `Prefetch` (o Windows recria e os programas abrem mais devagar), dumps de tela azul (`Minidump`), miniaturas (o Explorer mantém em uso) e `DISM /ResetBase` (tornaria atualizações irreversíveis).

**Cuidados:** apaga o **conteúdo** das pastas, nunca a pasta em si, e recusa caminhos suspeitos. Arquivos em uso são ignorados. Limpar temporários libera espaço, mas **não acelera o PC** de forma mensurável.

---

## adobe-remover.bat: desinstalar a Adobe por completo

**Quando usar:** o Creative Cloud não desinstala, instalação corrompida, sobras de versões antigas, ou você quer remover tudo da Adobe da máquina.

| Opção | O que faz |
|---|---|
| 1 | Inventário: produtos, serviços, tarefas, processos, pastas (com tamanho) e chaves. **Não altera nada** |
| 2 | Encerra processos e serviços Adobe |
| 3 | Desinstala produtos pelos desinstaladores registrados, com confirmação por produto. Creative Cloud por último |
| 4 | Remove serviços, tarefas agendadas e itens de inicialização |
| 5 | Remove pastas residuais em Program Files, Common Files e ProgramData |
| 6 | Remove **dados do usuário** em AppData (preferências, presets, cache). Irreversível |
| 7 | Remove chaves `Software\Adobe` do registro, com backup `.reg` |
| 8 | Remoção completa: 2 + 3 + 4 + 5 + 7 (não inclui a 6) |

**Atenção:**

- A opção 5 apaga **tudo** dentro das pastas `Adobe` do sistema, **inclusive o Acrobat Reader** e plug-ins de terceiros instalados ali. Para manter o Reader, use só a opção 3.
- Não toca em `Creative Cloud Files`, `Documentos\Adobe`, catálogos do Lightroom nem no arquivo `hosts`.
- Rode logado em uma conta que já seja administradora. Se você eleva com outra conta, `HKCU` e `AppData` apontam para o perfil errado.
- Para o Creative Cloud em si, a ferramenta oficial da Adobe (Creative Cloud Cleaner Tool) continua sendo a opção mais completa.

---

## amd-driver-cleaner.bat: limpar drivers de vídeo AMD

**Quando usar:** tela preta, travamentos, "o driver de vídeo parou de responder" (evento 4101), driver corrompido após atualização, ou quando você quer reinstalar o driver do zero.

| Opção | O que faz |
|---|---|
| 1 | Diagnóstico (não altera nada): GPU e versão do driver, pacotes no Driver Store, travamentos de vídeo dos últimos 7 dias, estado do Modo Seguro e do Windows Update |
| 2 | Reparo leve: limpa caches de shader e reinicia o adaptador de vídeo |
| 3 | Desinstala o AMD Software / Adrenalin |
| 4 | Remove os pacotes de driver de vídeo AMD do Driver Store (`pnputil`) |
| 5 | Remove serviços, tarefas, pastas, caches e chaves de registro da AMD de vídeo, com backup `.reg` |
| 6 | Limpeza completa: 3 + 4 + 5 |
| 7 | Bloqueia ou libera drivers via Windows Update, para ele não sobrescrever sua instalação limpa |
| 8 | Ativa ou desativa o boot em Modo Seguro |

**Fluxo recomendado para instalação limpa:**

1. Opção 1 (diagnóstico). Baixe o driver novo antes e deixe salvo.
2. Opção 3 no modo normal.
3. Opção 7 (bloquear) e desconecte a rede.
4. Opção 8 (ativar Modo Seguro) e reinicie.
5. No Modo Seguro, opções 4 e 5.
6. Opção 8 (desativar Modo Seguro) e reinicie.
7. Instale o driver novo e só então libere o Windows Update (opção 7).

**Atenção:**

- **BitLocker:** mudar o modo de boot pode exigir a chave de recuperação. Tenha-a em mãos.
- **Notebooks:** muitos exigem o driver do **fabricante**. O driver genérico da AMD pode correr o risco de não ser instalado.
- **APU Ryzen:** a iGPU/APU ficará sem driver até a reinstalação de um novo driver.
- Os drivers de chipsets da AMD **não são alterados e nem removidos**, somente os drivers de vídeo.
- **Alternativa mais profunda:** o DDU (Display Driver Uninstaller) em Modo Seguro limpa mais que este script. Este projeto é uma alternativa leve, auditável e sem ferramenta de terceiros.
- Se os travamentos continuarem depois da instalação limpa, a causa provavelmente não é driver. Verifique temperatura, fonte, overclock ou XMP (se aplicável).

---

## Segurança e transparência

- Todos os scripts são **texto puro** e sem ofuscação.
- **Nenhum script baixa arquivos nem envia dados.** O único acesso à rede é do `network-fix.bat`, que faz `ping` e `nslookup` para os testes.
- Os scripts usam PowerShell, que já vem no Windows, e pedem elevação de administrador via `Start-Process -Verb RunAs`.
- Toda ação destrutiva pede confirmação, e as que alteram o registro fazem backup `.reg` antes.
- Podem ser sinalizados por antivírus como "suspeitos", por mexerem em serviços, drivers e registro. É falso positivo comum para `.bat`. A solução é ler o código, não desativar o antivírus.

> **Aviso:** use por sua conta e risco. Scripts que alteram drivers, registro e arquivos de sistema podem causar problemas se usados sem entender o que fazem. Crie um ponto de restauração antes.

## Perguntas frequentes

**Meu Windows conecta mas não abre sites. Qual script?**
`network-fix.bat`, opção 7 (diagnóstico) e depois F (correção automática).

**Como saber se o problema é o DNS?**
Opção 4 do `network-fix.bat`. Se `1.1.1.1` resolve e o resolvedor atual não, o DNS do roteador ou do provedor está com defeito.

**Como limpar a pasta Temp do Windows com segurança?**
`clean-temp.bat`, opção 6.

**Como desinstalar o Adobe Creative Cloud completamente?**
`adobe-remover.bat`: opção 1 (inventário), opção 8 (remoção completa), reinicie e rode a 1 de novo.

**Como reinstalar o driver AMD do zero?**
`amd-driver-cleaner.bat`: siga o fluxo recomendado na seção do script.

**Funciona no Windows 7 ou 8?**
Não é suportado. O foco principal são versões do Windows 10 e 11.

**É um substituto do DDU?**
Não. É uma alternativa mais leve. O DDU é mais profundo.

## Compatibilidade

- **Foco:** Windows 10 e Windows 11 (64 bits), com Windows PowerShell 5.1 (já incluso).
- **Testado nas versões:** Windows 10 22H2, Windows 11 25H2 e 26H2 (funciona em todas as versões do Windows 10 e 11)
- **Idioma da interface:** pt-BR (Em breve terá uma alternativa em en-US).

## Créditos, contribuição e licença

- Scripts criados e codados por `@rablonkk`, revisado e corrigido por `@rablonkk`
- Este projeto **não é afiliado nem endossado** por Advanced Micro Devices (AMD) e Adobe.
- Contribuições são bem-vindas: abra uma *issue* descrevendo o problema (inclua a versão do Windows) ou um *pull request*. Mantenha os arquivos `.bat` com quebra de linha CRLF (o `.gitattributes` já cuida disso).
- Licença: [MIT](LICENSE).
