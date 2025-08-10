# 4장 - LiveView 시작하기

## 🎯 학습 목표

- Phoenix LiveView의 개념과 동작 원리 이해
- LiveView 생명주기와 상태 관리 학습
- 실시간 상호작용 구현 기초
- 첫 번째 인터랙티브 LiveView 만들기
- 이벤트 처리와 상태 업데이트 실습

## 🌟 Phoenix LiveView란?

### 개념

LiveView는 서버 렌더링된 HTML로 리치하고 실시간 사용자 경험을 제공하는 Phoenix의 기능입니다.

- **서버 중심**: 상태와 로직이 서버에 존재
- **실시간 업데이트**: WebSocket으로 변경사항만 전송
- **JavaScript 최소화**: 복잡한 클라이언트 코드 불필요
- **SEO 친화적**: 초기 렌더링은 정적 HTML

### 전통적인 SPA vs LiveView

#### Single Page Application (SPA)
```
Client (React/Vue) ←→ API Server
  ↑ (JavaScript)      ↑ (JSON)
복잡한 상태 관리    비즈니스 로직
```

#### Phoenix LiveView
```
Client (Browser) ←→ LiveView Server
  ↑ (Minimal JS)    ↑ (HTML Diff)
   DOM 조작만      비즈니스 로직 + 상태
```

## 🔄 LiveView 생명주기

### 1. 초기 렌더링 (Static)
```
1. HTTP GET 요청
2. 서버에서 초기 HTML 생성
3. 브라우저에 정적 페이지 표시
4. JavaScript가 WebSocket 연결 시작
```

### 2. LiveView 마운트 (Dynamic)
```
1. WebSocket 연결 성공
2. mount/3 콜백 실행
3. 초기 상태 설정
4. 실시간 상호작용 시작
```

### 3. 이벤트 처리 및 업데이트
```
1. 사용자 이벤트 발생 (클릭, 입력 등)
2. handle_event/3 콜백 실행
3. 상태 업데이트
4. 변경된 부분만 브라우저에 전송
5. DOM 업데이트
```

## 🚀 첫 번째 LiveView 만들기

### 1. 카운터 LiveView 생성

```elixir
# lib/phoenix_chat_web/live/counter_live.ex
defmodule PhoenixChatWeb.CounterLive do
  use PhoenixChatWeb, :live_view

  # 초기 렌더링과 LiveView 마운트 시 호출
  def mount(_params, _session, socket) do
    # 초기 상태 설정
    {:ok, assign(socket, :count, 0)}
  end

  # 화면 렌더링
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
      <h1 class="text-2xl font-bold text-center mb-6">카운터</h1>
      
      <div class="text-center">
        <div class="text-6xl font-bold text-blue-600 mb-8">
          {@count}
        </div>
        
        <div class="space-x-4">
          <button 
            phx-click="increment" 
            class="bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded"
          >
            증가 (+1)
          </button>
          
          <button 
            phx-click="decrement" 
            class="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded"
          >
            감소 (-1)
          </button>
          
          <button 
            phx-click="reset" 
            class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded"
          >
            초기화
          </button>
        </div>
      </div>
    </div>
    """
  end

  # 이벤트 처리
  def handle_event("increment", _params, socket) do
    {:noreply, assign(socket, :count, socket.assigns.count + 1)}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, assign(socket, :count, socket.assigns.count - 1)}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, :count, 0)}
  end
end
```

### 2. 라우터에 LiveView 경로 추가

```elixir
# lib/phoenix_chat_web/router.ex
scope "/", PhoenixChatWeb do
  pipe_through :browser

  get "/", PageController, :home
  get "/about", PageController, :about
  resources "/users", UserController
  
  # LiveView 경로 추가
  live "/counter", CounterLive
end
```

### 3. 테스트해보기

1. 서버 재시작: `mix phx.server`
2. 브라우저에서 `http://localhost:4000/counter` 접속
3. 버튼을 클릭해서 실시간 업데이트 확인

## 🎮 더 복잡한 예제: 간단한 게임

### 숫자 맞추기 게임

```elixir
# lib/phoenix_chat_web/live/guess_game_live.ex
defmodule PhoenixChatWeb.GuessGameLive do
  use PhoenixChatWeb, :live_view

  def mount(_params, _session, socket) do
    socket = 
      socket
      |> assign(:target_number, Enum.random(1..100))
      |> assign(:current_guess, "")
      |> assign(:message, "1부터 100 사이의 숫자를 맞춰보세요!")
      |> assign(:attempts, 0)
      |> assign(:game_over, false)
      |> assign(:guesses_history, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto bg-white rounded-lg shadow-md p-6">
      <h1 class="text-3xl font-bold text-center mb-6">🎯 숫자 맞추기 게임</h1>
      
      <div class="text-center mb-6">
        <p class={[
          "text-lg font-semibold p-3 rounded",
          message_color(@message)
        ]}>
          {@message}
        </p>
      </div>

      <div class="text-center mb-6">
        <p class="text-gray-600">시도 횟수: <span class="font-bold">{@attempts}</span></p>
      </div>

      <%= if not @game_over do %>
        <form phx-submit="guess" class="mb-6">
          <div class="flex space-x-2">
            <input
              type="number"
              name="guess"
              value={@current_guess}
              min="1"
              max="100"
              placeholder="숫자 입력"
              class="flex-1 px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500"
              phx-change="input_change"
            />
            <button
              type="submit"
              class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-6 rounded"
            >
              추측!
            </button>
          </div>
        </form>
      <% else %>
        <div class="text-center mb-6">
          <button
            phx-click="new_game"
            class="bg-green-500 hover:bg-green-600 text-white font-bold py-3 px-6 rounded-lg"
          >
            새 게임 시작
          </button>
        </div>
      <% end %>

      <!-- 추측 기록 -->
      <%= if @guesses_history != [] do %>
        <div class="mt-6">
          <h3 class="text-lg font-semibold mb-3">추측 기록</h3>
          <div class="space-y-2 max-h-40 overflow-y-auto">
            <%= for {guess, result, attempt} <- Enum.reverse(@guesses_history) do %>
              <div class="flex justify-between items-center p-2 bg-gray-50 rounded">
                <span>#{attempt}번째: <strong>{guess}</strong></span>
                <span class={[
                  "px-2 py-1 rounded text-sm",
                  result_color(result)
                ]}>{result}</span>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # 입력 값 변경 처리
  def handle_event("input_change", %{"guess" => guess}, socket) do
    {:noreply, assign(socket, :current_guess, guess)}
  end

  # 추측 처리
  def handle_event("guess", %{"guess" => guess_str}, socket) do
    case Integer.parse(guess_str) do
      {guess, ""} when guess >= 1 and guess <= 100 ->
        handle_guess(socket, guess)
      
      _ ->
        socket = assign(socket, :message, "1부터 100 사이의 올바른 숫자를 입력하세요!")
        {:noreply, socket}
    end
  end

  # 새 게임 시작
  def handle_event("new_game", _params, socket) do
    socket = 
      socket
      |> assign(:target_number, Enum.random(1..100))
      |> assign(:current_guess, "")
      |> assign(:message, "1부터 100 사이의 숫자를 맞춰보세요!")
      |> assign(:attempts, 0)
      |> assign(:game_over, false)
      |> assign(:guesses_history, [])

    {:noreply, socket}
  end

  # 추측 로직
  defp handle_guess(socket, guess) do
    %{
      target_number: target,
      attempts: attempts,
      guesses_history: history
    } = socket.assigns

    new_attempts = attempts + 1
    
    {message, result, game_over} = 
      cond do
        guess == target ->
          {"🎉 정답입니다! #{new_attempts}번 만에 맞췄어요!", "정답!", true}
        
        guess < target ->
          {"더 큰 숫자입니다!", "너무 작음", false}
        
        guess > target ->
          {"더 작은 숫자입니다!", "너무 큼", false}
      end

    new_history = [{guess, result, new_attempts} | history]

    socket = 
      socket
      |> assign(:message, message)
      |> assign(:attempts, new_attempts)
      |> assign(:game_over, game_over)
      |> assign(:guesses_history, new_history)
      |> assign(:current_guess, "")

    {:noreply, socket}
  end

  # 헬퍼 함수들
  defp message_color(message) do
    cond do
      String.contains?(message, "정답") -> "bg-green-100 text-green-800"
      String.contains?(message, "큰") or String.contains?(message, "작은") -> "bg-yellow-100 text-yellow-800"
      true -> "bg-blue-100 text-blue-800"
    end
  end

  defp result_color("정답!"), do: "bg-green-500 text-white"
  defp result_color("너무 작음"), do: "bg-red-100 text-red-800"
  defp result_color("너무 큼"), do: "bg-blue-100 text-blue-800"
end
```

### 라우터에 게임 경로 추가

```elixir
# lib/phoenix_chat_web/router.ex에 추가
live "/counter", CounterLive
live "/guess-game", GuessGameLive
```

## 📋 폼과 실시간 검증

### 실시간 사용자 등록 폼

```elixir
# lib/phoenix_chat_web/live/user_registration_live.ex
defmodule PhoenixChatWeb.UserRegistrationLive do
  use PhoenixChatWeb, :live_view
  alias PhoenixChat.Accounts
  alias PhoenixChat.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{})
    
    socket = 
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:email_available, nil)
      |> assign(:checking_email, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
      <h1 class="text-2xl font-bold text-center mb-6">사용자 등록</h1>
      
      <.form for={@form} phx-change="validate" phx-submit="save">
        <div class="mb-4">
          <.input 
            field={@form[:name]} 
            type="text" 
            label="이름"
            placeholder="홍길동"
            class="w-full"
          />
        </div>

        <div class="mb-4 relative">
          <.input 
            field={@form[:email]} 
            type="email" 
            label="이메일"
            placeholder="hong@example.com"
            class="w-full"
          />
          
          <%= if @checking_email do %>
            <div class="absolute right-3 top-8">
              <div class="animate-spin h-5 w-5 border-2 border-blue-500 border-t-transparent rounded-full"></div>
            </div>
          <% end %>
          
          <%= if @email_available == true do %>
            <p class="text-green-600 text-sm mt-1">✓ 사용 가능한 이메일입니다</p>
          <% end %>
          
          <%= if @email_available == false do %>
            <p class="text-red-600 text-sm mt-1">✗ 이미 사용 중인 이메일입니다</p>
          <% end %>
        </div>

        <div class="mb-6">
          <.input 
            field={@form[:bio]} 
            type="textarea" 
            label="소개" 
            placeholder="자기소개를 작성해주세요"
            rows="3"
            class="w-full"
          />
        </div>

        <button 
          type="submit"
          disabled={not @form.source.valid? or @email_available == false}
          class={[
            "w-full font-bold py-2 px-4 rounded",
            if(@form.source.valid? and @email_available != false,
              do: "bg-blue-500 hover:bg-blue-600 text-white",
              else: "bg-gray-300 text-gray-500 cursor-not-allowed"
            )
          ]}
        >
          등록하기
        </button>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = 
      %User{}
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    socket = assign(socket, :form, to_form(changeset))

    # 이메일이 변경된 경우 중복 검사
    socket = 
      if user_params["email"] && user_params["email"] != "" do
        check_email_availability(socket, user_params["email"])
      else
        assign(socket, :email_available, nil)
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        socket = 
          socket
          |> put_flash(:info, "사용자가 성공적으로 등록되었습니다!")
          |> push_navigate(to: ~p"/users/#{user}")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
  end

  defp check_email_availability(socket, email) do
    socket = assign(socket, :checking_email, true)
    
    # 실제로는 debounce를 구현해야 하지만, 여기서는 간단히 처리
    Process.send_after(self(), {:check_email, email}, 500)
    
    socket
  end

  def handle_info({:check_email, email}, socket) do
    available = is_nil(Accounts.get_user_by_email(email))
    
    socket = 
      socket
      |> assign(:email_available, available)
      |> assign(:checking_email, false)

    {:noreply, socket}
  end
end
```

## 🔧 LiveView 고급 기능

### 1. 임시 assigns

일시적으로만 필요한 데이터에 사용:

```elixir
def handle_event("show_success", _params, socket) do
  socket = 
    socket
    |> put_flash(:info, "성공!")
    |> assign(:temp_message, "작업이 완료되었습니다")  # 다음 렌더링 후 사라짐

  {:noreply, socket}
end
```

### 2. 프로세스 간 통신

다른 프로세스로부터 메시지 수신:

```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(PhoenixChat.PubSub, "user_updates")
  end
  
  {:ok, socket}
end

def handle_info({:user_updated, user}, socket) do
  # 다른 프로세스로부터 사용자 업데이트 알림 받음
  {:noreply, assign(socket, :user, user)}
end
```

### 3. 페이지 제목 동적 변경

```elixir
def mount(_params, _session, socket) do
  socket = assign(socket, :page_title, "카운터 게임")
  {:ok, socket}
end

def handle_event("increment", _params, socket) do
  count = socket.assigns.count + 1
  
  socket = 
    socket
    |> assign(:count, count)
    |> assign(:page_title, "카운터: #{count}")

  {:noreply, socket}
end
```

## 🧪 실습: 실시간 설문조사

다음 기능을 가진 실시간 설문조사를 만들어보세요:

### 요구사항
1. 질문과 여러 선택지 표시
2. 실시간 투표 결과 보기
3. 투표 후 결과만 보기 (재투표 불가)
4. 총 투표 수와 각 선택지 비율 표시

### 힌트

```elixir
defmodule PhoenixChatWeb.PollLive do
  use PhoenixChatWeb, :live_view

  def mount(_params, _session, socket) do
    # PubSub 구독으로 실시간 업데이트
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PhoenixChat.PubSub, "poll_updates")
    end
    
    # 초기 상태 설정
    socket = 
      socket
      |> assign(:question, "가장 좋아하는 프로그래밍 언어는?")
      |> assign(:options, ["Elixir", "Python", "JavaScript", "Go"])
      |> assign(:votes, %{"Elixir" => 0, "Python" => 0, "JavaScript" => 0, "Go" => 0})
      |> assign(:user_voted, false)
      |> assign(:selected_option, nil)

    {:ok, socket}
  end

  def handle_event("vote", %{"option" => option}, socket) do
    # 투표 처리 로직 구현
    # PubSub으로 다른 사용자들에게 알림
    {:noreply, socket}
  end

  def handle_info({:vote_update, votes}, socket) do
    # 다른 사용자의 투표 업데이트 받기
    {:noreply, assign(socket, :votes, votes)}
  end

  # render/1 함수와 헬퍼 함수들 구현
end
```

## ✅ 이해도 점검

### 기본 개념 확인
1. LiveView의 생명주기 순서를 설명해보세요
2. `mount/3`와 `handle_event/3`의 차이점은?
3. `assign/3`이 하는 역할은?
4. `{:noreply, socket}`의 의미는?

### 실전 문제
1. 버튼 클릭 시 1초 후에 카운터가 증가하도록 구현해보세요
2. 실시간으로 현재 시간을 표시하는 LiveView를 만들어보세요
3. 여러 사용자가 동시에 볼 수 있는 공유 카운터를 만들어보세요

## 📝 정리

이 장에서 배운 핵심 내용:

### LiveView 핵심 개념
- **서버 중심 상태 관리**: 클라이언트는 최소한의 JavaScript만 사용
- **실시간 업데이트**: WebSocket으로 변경사항만 전송
- **생명주기**: mount → render → handle_event → render...

### 주요 콜백 함수
```elixir
mount/3    # 초기화
render/1   # UI 렌더링  
handle_event/3  # 사용자 이벤트 처리
handle_info/2   # 프로세스 메시지 처리
```

### 상태 관리
```elixir
assign(socket, key, value)     # 상태 설정
socket.assigns.key            # 상태 접근  
update(socket, key, fun)      # 상태 업데이트
```

### 이벤트 처리
```heex
<button phx-click="event_name">Click</button>
<form phx-submit="submit_event" phx-change="validate">
<input phx-blur="blur_event" phx-focus="focus_event">
```

## 🚀 다음 단계

다음 장에서는 LiveView의 더 고급 기능들과 실시간 상호작용을 심화 학습하겠습니다.

**다음**: [5장 - LiveView 고급 기능과 실시간 상호작용](./05-advanced-liveview.md)