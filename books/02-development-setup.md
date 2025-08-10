# 2장 - 개발 환경 설정과 첫 Phoenix 앱

## 🎯 학습 목표

- Elixir와 Phoenix 개발 환경 설정
- 첫 Phoenix 애플리케이션 생성하기
- Phoenix 디렉토리 구조 이해
- 기본적인 Phoenix 명령어 익히기
- 개발 서버 실행과 기본 페이지 확인

## 🛠️ 개발 환경 설정

### 필요한 도구들

1. **Elixir** (1.15+)
2. **Phoenix Framework** (1.8+)
3. **Node.js** (프론트엔드 애셋 빌드용)
4. **SQLite** (데이터베이스)
5. **Git** (버전 관리)

### macOS 설치

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Elixir 설치
brew install elixir

# Node.js 설치
brew install node

# Phoenix 설치
mix archive.install hex phx_new

# 설치 확인
elixir --version
node --version
mix phx.new --version
```

### Ubuntu/Linux 설치

```bash
# Elixir 설치
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update
sudo apt-get install esl-erlang elixir

# Node.js 설치
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Phoenix 설치
mix archive.install hex phx_new
```

### Windows 설치

1. [Elixir 공식 사이트](https://elixir-lang.org/install.html)에서 설치 프로그램 다운로드
2. [Node.js 공식 사이트](https://nodejs.org/)에서 LTS 버전 설치
3. PowerShell에서 Phoenix 설치:
   ```powershell
   mix archive.install hex phx_new
   ```

## 🎨 첫 Phoenix 애플리케이션 생성

### 프로젝트 생성

```bash
# phoenix_chat 프로젝트 생성
mix phx.new phoenix_chat --database sqlite3

# 프로젝트 디렉토리로 이동
cd phoenix_chat

# 의존성 설치 및 설정
mix setup

# 개발 서버 시작
mix phx.server
```

성공하면 다음과 같은 출력을 볼 수 있습니다:

```
[info] Running PhoenixChatWeb.Endpoint with Bandit 1.5.7 at 127.0.0.1:4000 (http)
[info] Access PhoenixChatWeb.Endpoint at http://localhost:4000
[watch] build finished, watching for changes...
```

브라우저에서 `http://localhost:4000`으로 접속하면 Phoenix 기본 페이지를 볼 수 있습니다.

### 대화형 셸에서 실행

```bash
# IEx (Interactive Elixir)에서 Phoenix 실행
iex -S mix phx.server
```

이렇게 하면 서버를 실행하면서 동시에 Elixir REPL에 접근할 수 있습니다.

## 📁 Phoenix 프로젝트 구조 이해

### 전체 구조 개요

```
phoenix_chat/
├── _build/              # 컴파일된 파일들
├── assets/              # 프론트엔드 애셋 (CSS, JS)
├── config/              # 설정 파일들
├── deps/                # 외부 의존성들
├── lib/                 # 메인 애플리케이션 코드
├── priv/                # 프라이빗 파일들 (마이그레이션, 정적 파일)
├── test/                # 테스트 파일들
├── mix.exs              # 프로젝트 설정과 의존성
└── mix.lock             # 의존성 버전 잠금
```

### 핵심 디렉토리 상세

#### `lib/` 디렉토리

```
lib/
├── phoenix_chat/                    # 비즈니스 로직 (Context)
│   ├── application.ex              # OTP 애플리케이션 설정
│   ├── mailer.ex                   # 이메일 기능
│   └── repo.ex                     # 데이터베이스 접근
├── phoenix_chat_web/                # 웹 인터페이스
│   ├── components/                 # 재사용 가능한 컴포넌트
│   ├── controllers/                # HTTP 요청 처리
│   ├── live/                       # LiveView 파일들 (나중에 생성)
│   ├── endpoint.ex                 # HTTP 엔드포인트
│   ├── gettext.ex                  # 국제화
│   ├── router.ex                   # 라우팅 설정
│   └── telemetry.ex                # 모니터링
├── phoenix_chat.ex                  # 메인 애플리케이션 모듈
└── phoenix_chat_web.ex              # 웹 계층 공통 설정
```

#### `config/` 디렉토리

```
config/
├── config.exs           # 공통 설정
├── dev.exs              # 개발 환경 설정
├── prod.exs             # 운영 환경 설정
├── runtime.exs          # 런타임 설정
└── test.exs             # 테스트 환경 설정
```

#### `assets/` 디렉토리

```
assets/
├── css/
│   └── app.css          # 메인 CSS 파일
├── js/
│   └── app.js           # 메인 JavaScript 파일
└── vendor/              # 외부 프론트엔드 라이브러리
```

## 🔧 주요 Phoenix 명령어

### 개발 관련 명령어

```bash
# 개발 서버 시작
mix phx.server

# 대화형 셸과 함께 서버 시작
iex -S mix phx.server

# 의존성 설치 및 데이터베이스 설정
mix setup

# 데이터베이스 생성
mix ecto.create

# 마이그레이션 실행
mix ecto.migrate

# 테스트 실행
mix test

# 코드 포맷팅
mix format

# 의존성 확인
mix deps.get
```

### 생성기(Generator) 명령어

```bash
# HTML 리소스 생성
mix phx.gen.html Context Model models field:type

# JSON API 리소스 생성  
mix phx.gen.json Context Model models field:type

# LiveView 리소스 생성
mix phx.gen.live Context Model models field:type

# Context 생성
mix phx.gen.context Context Model models field:type

# 마이그레이션 생성
mix ecto.gen.migration migration_name
```

## 🌐 기본 라우팅 이해

### `router.ex` 파일 살펴보기

```elixir
# lib/phoenix_chat_web/router.ex
defmodule PhoenixChatWeb.Router do
  use PhoenixChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixChatWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # API routes would go here
  # scope "/api", PhoenixChatWeb do
  #   pipe_through :api
  # end
end
```

### 파이프라인 이해

- **`:browser`**: HTML 요청용 파이프라인
- **`:api`**: JSON API 요청용 파이프라인

각 파이프라인은 요청이 컨트롤러에 도달하기 전에 거치는 미들웨어들의 연결입니다.

## 🎨 첫 페이지 커스터마이징

### 홈 페이지 수정하기

#### 1. 컨트롤러 확인

```elixir
# lib/phoenix_chat_web/controllers/page_controller.ex
defmodule PhoenixChatWeb.PageController do
  use PhoenixChatWeb, :controller

  def home(conn, _params) do
    # 홈 페이지 렌더링
    render(conn, :home)
  end
end
```

#### 2. HTML 템플릿 수정

```heex
<!-- lib/phoenix_chat_web/controllers/page_html/home.html.heex -->
<div class="mx-auto max-w-2xl">
  <h1 class="text-4xl font-bold text-center mb-8">
    🚀 Phoenix Chat에 오신 걸 환영합니다!
  </h1>
  
  <div class="bg-white shadow rounded-lg p-6">
    <h2 class="text-2xl font-semibold mb-4">실시간 채팅 애플리케이션</h2>
    
    <p class="text-gray-600 mb-4">
      Phoenix Framework와 LiveView를 사용하여 만든 실시간 채팅 애플리케이션입니다.
    </p>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div class="feature-card">
        <h3 class="font-bold text-lg">⚡ 실시간 메시징</h3>
        <p class="text-gray-600">즉시 메시지 전송과 수신</p>
      </div>
      
      <div class="feature-card">
        <h3 class="font-bold text-lg">👥 다중 채팅방</h3>
        <p class="text-gray-600">여러 채팅방 지원</p>
      </div>
      
      <div class="feature-card">
        <h3 class="font-bold text-lg">🟢 온라인 상태</h3>
        <p class="text-gray-600">사용자 온라인 상태 표시</p>
      </div>
      
      <div class="feature-card">
        <h3 class="font-bold text-lg">📁 파일 공유</h3>
        <p class="text-gray-600">이미지 및 파일 업로드</p>
      </div>
    </div>
  </div>
</div>

<style>
  .feature-card {
    @apply bg-gray-50 p-4 rounded border;
  }
</style>
```

### 새로운 라우트 추가하기

#### 1. 라우터에 경로 추가

```elixir
# lib/phoenix_chat_web/router.ex에 추가
scope "/", PhoenixChatWeb do
  pipe_through :browser

  get "/", PageController, :home
  get "/about", PageController, :about  # 새로운 경로
end
```

#### 2. 컨트롤러에 액션 추가

```elixir
# lib/phoenix_chat_web/controllers/page_controller.ex에 추가
def about(conn, _params) do
  render(conn, :about)
end
```

#### 3. 템플릿 파일 생성

```heex
<!-- lib/phoenix_chat_web/controllers/page_html/about.html.heex -->
<div class="mx-auto max-w-2xl">
  <h1 class="text-3xl font-bold mb-6">Phoenix Chat 소개</h1>
  
  <div class="prose max-w-none">
    <p>
      Phoenix Chat은 학습 목적으로 만들어진 실시간 채팅 애플리케이션입니다.
    </p>
    
    <h2>사용 기술</h2>
    <ul>
      <li>Elixir - 함수형 프로그래밍 언어</li>
      <li>Phoenix Framework - 웹 애플리케이션 프레임워크</li>
      <li>LiveView - 실시간 인터랙티브 웹 UI</li>
      <li>TailwindCSS - 유틸리티 CSS 프레임워크</li>
    </ul>
  </div>
  
  <div class="mt-8">
    <.link href="/" class="text-blue-600 hover:underline">
      ← 홈으로 돌아가기
    </.link>
  </div>
</div>
```

## 🧪 실습: 간단한 API 엔드포인트 만들기

### JSON API 만들기

#### 1. 라우터에 API 경로 추가

```elixir
# lib/phoenix_chat_web/router.ex
scope "/api", PhoenixChatWeb do
  pipe_through :api

  get "/status", StatusController, :index
end
```

#### 2. 컨트롤러 생성

```elixir
# lib/phoenix_chat_web/controllers/status_controller.ex
defmodule PhoenixChatWeb.StatusController do
  use PhoenixChatWeb, :controller

  def index(conn, _params) do
    status = %{
      app_name: "Phoenix Chat",
      version: "1.0.0",
      status: "running",
      timestamp: DateTime.utc_now()
    }

    json(conn, status)
  end
end
```

#### 3. 테스트해보기

```bash
curl http://localhost:4000/api/status
```

예상 응답:
```json
{
  "app_name": "Phoenix Chat",
  "version": "1.0.0", 
  "status": "running",
  "timestamp": "2024-01-01T12:00:00.000000Z"
}
```

## ✅ 환경 설정 점검

다음 명령어들이 모두 정상 작동하는지 확인하세요:

```bash
# 1. Elixir 버전 확인
elixir --version

# 2. Phoenix 설치 확인
mix phx.new --version

# 3. 개발 서버 시작
mix phx.server

# 4. 테스트 실행
mix test

# 5. 의존성 확인
mix deps

# 6. 포맷팅 확인
mix format --check-formatted
```

## 🐛 일반적인 문제와 해결방법

### 1. 포트 4000이 이미 사용 중인 경우

```bash
# 다른 포트로 실행
PORT=4001 mix phx.server
```

### 2. 의존성 문제

```bash
# 의존성 다시 가져오기
rm -rf deps _build
mix deps.get
mix deps.compile
```

### 3. 애셋 빌드 문제

```bash
cd assets
npm install
cd ..
mix assets.build
```

### 4. 데이터베이스 문제

```bash
# 데이터베이스 재생성
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

## 📝 정리

이 장에서 배운 내용:

- **개발 환경 설정**: Elixir, Phoenix, Node.js 설치
- **프로젝트 생성**: `mix phx.new` 명령어 사용
- **디렉토리 구조**: `lib/`, `config/`, `assets/` 등의 역할
- **기본 명령어**: 서버 실행, 테스트, 포맷팅
- **라우팅**: HTTP 요청을 컨트롤러로 연결
- **MVC 패턴**: 모델-뷰-컨트롤러 구조 이해

## 🚀 다음 단계

다음 장에서는 Phoenix의 핵심 개념인 Context, Controller, View에 대해 자세히 알아보겠습니다.

**다음**: [3장 - Phoenix 기본 개념과 MVC 패턴](./03-phoenix-mvc-concepts.md)