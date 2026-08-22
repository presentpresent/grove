# grove

한 작업에 레포 여럿을 모아 심고, 레포마다 AI 세션을 붙이는 도구

> [English README](README.md) · 영어로 보려면 `GROVE_LANG=en`

기능 하나를 만드는 데 백엔드·BFF·앱 레포를 동시에 건드려야 하는 사람을 위한 것. 레포마다 워크트리를 따고, 브랜치 이름을 맞추고, 끝나면 정리하는 일을 한 명령으로 묶음

레포가 하나면 `git worktree add` 를 직접 쓰는 게 낫다. grove 는 **여러 개일 때** 값이 나옴

## 설치

```bash
npm i -g @presentpresent/grove
grove init
```

`grove init` 이 이 머신의 레포 배치와 브랜치 관행을 살펴보고 설정을 제안함. 설치 없이 먼저 보려면:

```bash
npx @presentpresent/grove init --dry-run
```

bash 3.2 만 있으면 되고 의존성은 없다. Node 는 배포 통로일 뿐임

## 쓰는 법

```bash
grove new checkout-redesign notification-worker web-bff
```

`~/Projects/worktrees/checkout-redesign/` 아래에 레포별 워크트리가 생기고, 전부 같은 브랜치(`feature/checkout-redesign`)를 가리킴. `PLAN.md` 초안도 같이 놓임

```bash
grove open checkout-redesign          # 계획 단계 — 화면 배치 + 계획 세션
grove open checkout-redesign --exec   # 레포별 AI 세션 기동
grove add checkout-redesign api-server   # 도중에 레포 추가
grove ls                      # 지금 열린 것
grove rm checkout-redesign            # 문서 아카이브 + 워크트리·브랜치 정리
```

| 명령 | 하는 일 |
|---|---|
`new` | 워크트리 생성 + PLAN.md 배치 |
`add` | 기존 작업에 레포 추가 (브랜치는 물려받음) |
`open` | 화면 배치. `--exec` 면 레포별 AI 세션까지 |
`ls` | 활성 워크트리 조회 |
`rm` | 아카이브 → 워크트리 제거 → 머지된 브랜치 정리 |
`export` | 끝난 작업의 회고 draft 생성 |
`init` | 이 머신에 맞춰 설정 생성 |
`status` | 한 화면 요약 — 레포별 브랜치·커밋·PR 상태·체크리스트 진행률 |
`tell` | 레포 세션 전부에 통지 (`--to` 로 한 곳만) |
`ask` | 레포 세션이 계획 세션에 확인 요청 |

## 지금 어디까지 왔나

```bash
grove status checkout-redesign
```

```
checkout-redesign — 마지막 손댄 지 0일

레포                      브랜치                           커밋   변경   PR
----------------------------------------------------------------------
api-server               feature/checkout-redesign          18     ·  #1539 merged
web-bff                  feature/checkout-redesign-p4       12     ·  #3245 merged
web-client               feature/checkout-redesign           5     3  #44 open

문서
  PLAN.md            43/82  (52%)  120줄
  PITFALLS.md        538줄

세션 5개 도는 중
```

**판단은 안 하고 숫자만 냄.** git 을 먼저 보고 문서는 보조로 씀 — 코드가 진실이기 때문임

## PLAN.md 로 소통함

레포별 세션은 서로를 못 봄. 그래서 워크트리 루트의 `PLAN.md` 가 계약 역할을 함. 계획 세션이 여기를 고치면 각 레포 세션이 그걸 읽고 자기 몫을 진행하는 구조

`grove rm` 은 PLAN.md 를 아카이브로 옮기므로 나중에 "그때 왜 그렇게 했지" 를 되짚을 수 있음

### 통로는 양방향, 둘 다 자동

계획 세션과 레포 세션은 서로의 컨텍스트를 못 봄. 그래서 방향을 둘로 나눠둠

| | |
|---|---|
`grove tell <작업명> [메시지]` | 계획 → 레포 전부. `--to <레포>` 면 한 곳만 |
`grove ask "<질문>"` | 레포 → 계획. `QUESTIONS.md` 에 기록하고 알림 |

`hooks/plan-notify.sh` 가 앞쪽을 자동으로 만듦 — PLAN.md 의 **계약 절**을 고치면 레포 세션 전부에 diff 가 감. 계약 절만 감시함. 체크리스트에 체크했다고 세션 다섯 개를 깨우면 안 됨

### 문서는 길어지기 전에 쪼갤 것

살아있는 계약과 쌓인 이력을 한 파일에 두면, 매일 볼 40줄을 수백 줄에서 찾게 됨. PLAN.md 가 300줄을 넘기 시작하면 **갱신 빈도로** 쪼갤 것

| | |
|---|---|
`PLAN.md` | 계약·체크리스트·배포 순서·아직 막힌 것 — **매일 봄** |
`DESIGN.md` | 왜 이렇게 골랐나 — 한 번 쓰고 안 봄 |
`PITFALLS.md` | 함정·검증 기록·결정 로그 — 걸릴 때만 |

옮긴 자리에는 한 줄 포인터를 남길 것

## 설정

`~/.config/grove/config` 하나만 보면 됨. `grove init` 이 만들어줌

| 변수 | 뜻 |
|---|---|
`GROVE_REPOS` | 레포 원본 경로. **콜론으로 여러 곳** (`~/Projects/repos:~/dev`) |
`GROVE_ROOT` `GROVE_TREES` `GROVE_ARCHIVE` | 워크스페이스 경로 |
`GROVE_BRANCH` | 브랜치 템플릿. `{type}` `{name}` 이 치환됨 |
`GROVE_TYPE` `GROVE_TYPES` | 작업 종류 기본값과 목록 |
`GROVE_MUX` | 화면 도구 (herdr 등) |
`GROVE_LANG` | `en` · `ko` · `auto` (`LANG` 을 봄. 안 잡히면 영어) |
`GROVE_CASEBOOK` | 회고 기록 위치. 비우면 기능이 꺼짐 |

브랜치 템플릿은 prefix 가 아니라 **통째로 템플릿**이라 이런 것들이 다 담김:

```
{type}/ACME-{name}      → feature/ACME-checkout-redesign
{type}/{name}         → fix/cart-crash
alice/{name}          → alice/cart-crash
{name}-wip            → cart-crash-wip
```

환경변수가 설정 파일보다 우선하므로 한 번만 다르게 쓰려면 앞에 붙이면 됨:

```bash
GROVE_REPOS=~/other grove ls
```

## AI 스킬

`grove init` 이 `~/.claude/skills/` 에 두 개를 깔아줌

- `/grove-start` — 레포 특정 → 작업명 확정 → `grove new` → PLAN.md 초안 → `grove open`
- `/grove-resume` — 하던 작업 복귀. 어디까지 했는지 복원하고 화면까지 되살림

## 화면

`grove open` 과 `grove tell`, `grove ask` 의 알림 부분만 [herdr](https://github.com/herdrdev/herdr) 를 씀. 나머지(`new` `add` `ls` `rm` `export` `init`)는 순수 git 이라 herdr 없이 돌아감

| | herdr 없을 때 |
|---|---|
`new` `add` `ls` `rm` `export` `init` | 정상 동작 |
`ask` | QUESTIONS.md 기록은 되고 알림만 생략 |
`tell` `open` | 명확한 메시지와 함께 실패 |

tmux·zellij 는 `grove init` 이 감지하지만 페인 배치는 못 함. herdr 만 됨

## 알아둘 것

- 워크트리를 만든 레포는 `.git/worktrees/*/gitdir` 에 절대경로가 박힘. **레포 디렉토리를 옮기면 깨짐**
- 워크트리의 `node_modules` 는 원본에 symlink 됨. deps 를 바꾸려면 먼저 `rm node_modules` 후 설치할 것. 안 그러면 원본이 오염됨
- GitHub org 룰로 브랜치 이름이 강제되는 경우가 있는데 그 규칙은 `admin:org` 없이 API 로 안 보임. `grove init` 이 이력에서 추론하는 이유

## 라이선스

MIT
