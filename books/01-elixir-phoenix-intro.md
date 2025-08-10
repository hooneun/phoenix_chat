# 1장 - Elixir와 Phoenix 소개

## 🎯 학습 목표

- Elixir 언어의 핵심 특징과 철학 이해
- Phoenix Framework의 장점과 특징 파악
- Actor 모델과 OTP(Open Telecom Platform) 기본 개념 학습
- 실시간 애플리케이션에 Phoenix가 적합한 이유 이해

## 📚 Elixir 언어 소개

### Elixir란?

Elixir는 José Valim이 2011년에 만든 동적 함수형 프로그래밍 언어입니다. Erlang Virtual Machine(BEAM) 위에서 실행되며, Erlang의 강력한 동시성과 내결함성을 Ruby와 같은 친숙한 문법으로 사용할 수 있습니다.

### 주요 특징

#### 1. **Actor 모델 기반 동시성**
```elixir
# 프로세스 생성 (Erlang 프로세스, OS 프로세스와 다름)
pid = spawn(fn -> 
  receive do
    {:hello, caller} -> send(caller, :world)
  end
end)

# 메시지 전송
send(pid, {:hello, self()})

# 메시지 수신
receive do
  :world -> IO.puts("Hello World!")
end
```

#### 2. **불변성(Immutability)**
```elixir
# 데이터는 변경되지 않고 새로운 데이터가 생성됨
list = [1, 2, 3]
new_list = [0 | list]  # [0, 1, 2, 3]
IO.inspect(list)       # [1, 2, 3] - 원본은 변경되지 않음
```

#### 3. **패턴 매칭**
```elixir
# 튜플 패턴 매칭
{:ok, result} = {:ok, "성공"}
IO.puts(result)  # "성공"

# 함수에서의 패턴 매칭
defmodule Calculator do
  def add({:ok, a}, {:ok, b}), do: {:ok, a + b}
  def add({:error, _}, _), do: {:error, "첫 번째 값이 에러"}
  def add(_, {:error, _}), do: {:error, "두 번째 값이 에러"}
end
```

#### 4. **파이프 연산자**
```elixir
# 전통적인 방식
result = String.upcase(String.trim("  hello world  "))

# 파이프 연산자 사용
result = "  hello world  "
         |> String.trim()
         |> String.upcase()
```

## 🌐 Phoenix Framework 소개

### Phoenix란?

Phoenix는 Elixir로 작성된 웹 애플리케이션 프레임워크입니다. Rails와 Django에서 영감을 받았지만, Elixir의 동시성과 내결함성을 활용하여 실시간 기능과 높은 성능을 제공합니다.

### Phoenix의 핵심 장점

#### 1. **높은 성능**
- 수백만 개의 동시 연결 처리 가능
- 낮은 지연시간과 높은 처리량
- 효율적인 메모리 사용

#### 2. **실시간 기능**
- WebSocket을 통한 양방향 통신
- Phoenix Channels로 실시간 기능 구현
- LiveView로 JavaScript 없이 인터랙티브 UI

#### 3. **내결함성**
- 하나의 프로세스 오류가 전체 시스템에 영향 미치지 않음
- "Let it crash" 철학
- OTP 감독자 트리로 자동 복구

## 🏗️ Phoenix 애플리케이션 구조

### MVC 패턴과 Context

Phoenix는 전통적인 MVC 패턴을 사용하지만, Context라는 개념을 추가로 도입합니다:

```
lib/
├── phoenix_chat/              # Context (비즈니스 로직)
│   ├── accounts/             # 사용자 관리 Context
│   ├── chat/                 # 채팅 기능 Context
│   └── ...
├── phoenix_chat_web/          # Web Layer
│   ├── controllers/          # Controllers
│   ├── live/                 # LiveViews
│   ├── components/           # 재사용 가능한 컴포넌트
│   └── ...
```

### 요청 생명주기

```
브라우저 요청 → Endpoint → Router → Controller/LiveView → Context → Database
                  ↓
              Channels (실시간 통신용)
```

## 💡 실시간 채팅에서 Phoenix가 유리한 이유

### 1. **동시 사용자 처리**
```elixir
# 각 사용자는 독립적인 프로세스
# 수백만 사용자도 효율적으로 처리
defmodule ChatRoom do
  use GenServer
  
  # 각 채팅방이 독립적인 프로세스
  def start_link(room_id) do
    GenServer.start_link(__MODULE__, %{room_id: room_id, users: []})
  end
end
```

### 2. **실시간 메시지 전송**
```elixir
# PubSub을 이용한 실시간 메시지 브로드캐스팅
Phoenix.PubSub.broadcast(
  MyApp.PubSub,
  "room:#{room_id}",
  {:new_message, message}
)
```

### 3. **상태 관리**
```elixir
# 각 사용자의 상태를 프로세스 메모리에 보관
# 빠른 접근과 실시간 업데이트
defmodule UserSession do
  use GenServer
  
  def init(user_id) do
    {:ok, %{
      user_id: user_id,
      online: true,
      current_room: nil,
      typing: false
    }}
  end
end
```

## 🎭 Actor 모델 이해하기

### Actor 모델이란?

Actor 모델은 동시성을 다루는 수학적 모델로, 다음 원칙을 따릅니다:

1. **Actor는 독립적**: 각자의 메모리 공간을 가짐
2. **메시지로만 소통**: 직접적인 데이터 공유 없음
3. **비동기 처리**: 메시지 전송과 수신이 비동기

### 채팅 애플리케이션에서의 Actor 모델

```elixir
# 사용자 = Actor
# 메시지 = Actor 간 통신
# 채팅방 = Actor 그룹

defmodule ChatExample do
  def user_actor(name) do
    receive do
      {:message, from, text} ->
        IO.puts("#{name}이 #{from}으로부터 메시지 받음: #{text}")
        user_actor(name)
      
      {:send_message, to, text} ->
        send(to, {:message, name, text})
        user_actor(name)
    end
  end
end

# 사용자 생성
alice = spawn(fn -> ChatExample.user_actor("Alice") end)
bob = spawn(fn -> ChatExample.user_actor("Bob") end)

# 메시지 전송
send(alice, {:send_message, bob, "안녕하세요!"})
```

## 🧪 실습: 간단한 Elixir 프로그램

### 메시지 전달 시스템 만들기

```elixir
# message_system.ex
defmodule MessageSystem do
  def create_user(name) do
    spawn(fn -> user_loop(name, []) end)
  end
  
  defp user_loop(name, messages) do
    receive do
      {:send, to_pid, message} ->
        send(to_pid, {:receive, self(), name, message})
        user_loop(name, messages)
      
      {:receive, from_pid, sender_name, message} ->
        new_message = "#{sender_name}: #{message}"
        IO.puts("#{name}이 메시지 받음 - #{new_message}")
        user_loop(name, [new_message | messages])
      
      {:get_messages, caller} ->
        send(caller, {:messages, messages})
        user_loop(name, messages)
    end
  end
  
  def send_message(from_pid, to_pid, message) do
    send(from_pid, {:send, to_pid, message})
  end
  
  def get_messages(user_pid) do
    send(user_pid, {:get_messages, self()})
    receive do
      {:messages, messages} -> messages
    end
  end
end

# 사용 예제
alice = MessageSystem.create_user("Alice")
bob = MessageSystem.create_user("Bob")

MessageSystem.send_message(alice, bob, "안녕하세요!")
MessageSystem.send_message(bob, alice, "안녕하세요, Alice!")

IO.inspect(MessageSystem.get_messages(alice))
IO.inspect(MessageSystem.get_messages(bob))
```

## ✅ 이해도 점검

다음 질문들을 스스로 답해보세요:

1. Elixir의 프로세스와 OS의 프로세스는 어떻게 다른가요?
2. 패턴 매칭의 장점은 무엇인가요?
3. Phoenix가 실시간 애플리케이션에 적합한 이유 3가지는?
4. Actor 모델에서 Actor들은 어떻게 소통하나요?
5. 불변성이 동시성에 어떤 도움을 주나요?

## 📝 정리

이 장에서 배운 핵심 내용:

- **Elixir**는 Erlang VM 기반의 함수형 언어
- **Actor 모델**로 안전한 동시성 처리
- **Phoenix**는 높은 성능과 실시간 기능 제공
- **불변성**과 **패턴 매칭**으로 안정적인 코드
- **"Let it crash"** 철학으로 내결함성 확보

## 🚀 다음 단계

다음 장에서는 실제 개발 환경을 설정하고 첫 Phoenix 애플리케이션을 만들어보겠습니다.

**다음**: [2장 - 개발 환경 설정과 첫 Phoenix 앱](./02-development-setup.md)