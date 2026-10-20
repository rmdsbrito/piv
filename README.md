# PIV 2026 – Projeto

Projeto de PIV (Técnico, MEEC) em MATLAB. Autores: `<NOMES DO GRUPO>` (grupo `<XX>`).

O projeto tem três partes:

| Pasta    | Conteúdo                                                        |
|----------|-----------------------------------------------------------------|
| `part1/` | Homografias por frame a partir de RGB (referência e modelo do court) |
| `part2/` | Registo 3D com RGB-D e fusão de nuvens de pontos                |
| `part3/` | Aplicação                                                       |

## Estrutura

```
piv/
├── part1/                 main1.m, part1.m, dlt_homography.m, ransac_homography.m, tests/
├── part2/                 main2.m, ...
├── part3/
├── external/
│   └── VisionIST_matlab/  submodule (repo do professor; NÃO editar)
├── data/                  dados locais (fora do git)
├── startup.m              adiciona as pastas ao path do MATLAB
└── .gitignore
```

## Requisitos

- Git, com chave SSH configurada no GitHub (o submodule usa URL SSH)
- Acesso ao repo `sipg-isr/VisionIST_matlab`
- MATLAB `2026b`

## Começar (primeira vez)

Clonar **com** submodules:

```bash
git clone --recursive git@github.com:<UTILIZADOR>/piv.git
cd piv
```

Se já clonaste sem `--recursive`, a pasta `external/VisionIST_matlab` aparece vazia. Corrige com:

```bash
git submodule update --init
```

Depois abre o MATLAB **na raiz do repo** (para o `startup.m` correr sozinho):

```bash
matlab &
```

Verifica no MATLAB que o toolbox está no path, por exemplo com `which <um_script_do_VisionIST>`.

## Dados

A pasta `data/` não vai para o git. Descarrega os datasets (ver Google Drive da cadeira e o Apêndice B do enunciado) e coloca-os em `data/`, mantendo uma subpasta por sequência. Ficheiros `.mat` gerados (features, homografias, nuvens) também ficam de fora.

## Fluxo de trabalho

- Não trabalhes diretamente no `main`. Cria um branch por funcionalidade:
  ```bash
  git checkout -b <nome>/<funcionalidade>
  ```
- Faz commits pequenos e com mensagem clara. Antes de fazer push, corre `git pull --rebase origin main`.
- Quando a funcionalidade estiver testada, faz merge para o `main` (pull request ou merge local).
- Para receber o trabalho dos colegas:
  ```bash
  git pull
  git submodule update --init
  ```

## Atualizar o VisionIST

O submodule fica fixo num commit. Para atualizar para a versão mais recente do professor:

```bash
git submodule update --remote external/VisionIST_matlab
git add external/VisionIST_matlab
git commit -m "Atualiza VisionIST"
```

Não edites ficheiros dentro de `external/`. Se precisares de alterar algum script, copia-o para a tua pasta.

