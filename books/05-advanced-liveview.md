# 5장 - LiveView 고급 기능과 실시간 상호작용

## 🎯 학습 목표

- LiveView Streams를 이용한 대용량 데이터 처리
- 컴포넌트 시스템과 재사용 가능한 UI 구축
- JavaScript Hook을 이용한 클라이언트 사이드 통합
- 파일 업로드와 진행률 표시
- 실시간 검색과 필터링 구현

## 📊 LiveView Streams 마스터하기

### Streams의 필요성

전통적인 assigns는 메모리에 모든 데이터를 보관하므로, 대량의 데이터 처리 시 문제가 발생할 수 있습니다.

```elixir
# ❌ 메모리 문제 발생 가능
def mount(_params, _session, socket) do
  messages = Chat.list_all_messages()  # 수천 개의 메시지
  {:ok, assign(socket, :messages, messages)}
end
```

### Streams 사용법

```elixir
# ✅ 메모리 효율적인 방법
def mount(_params, _session, socket) do
  socket = 
    socket
    |> stream(:messages, Chat.get_recent_messages(50))
    |> assign(:page, 1)
    
  {:ok, socket}
end
```

### 실시간 메시지 목록 구현

```elixir
# lib/phoenix_chat_web/live/message_list_live.ex
defmodule PhoenixChatWeb.MessageListLive do
  use PhoenixChatWeb, :live_view
  alias PhoenixChat.Chat

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PhoenixChat.PubSub, "messages")
    end
    
    messages = Chat.list_recent_messages(20)
    
    socket = 
      socket
      |> stream(:messages, messages)
      |> assign(:message_form, to_form(%{"content" => ""}))
      |> assign(:loading_more, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto bg-white rounded-lg shadow-md">
      <!-- 헤더 -->
      <div class="bg-blue-500 text-white p-4 rounded-t-lg">
        <h1 class="text-xl font-bold">실시간 메시지</h1>
      </div>

      <!-- 메시지 목록 -->
      <div 
        id="messages-container"
        phx-update="stream"
        phx-viewport-top="load-more-messages"
        phx-page-loading
        class="h-96 overflow-y-auto p-4 space-y-3"
      >
        <div :for={{dom_id, message} <- @streams.messages} id={dom_id}>
          <div class={[
            "p-3 rounded-lg max-w-xs",
            if(message.user_id == @current_user_id,
              do: "bg-blue-100 ml-auto text-right",
              else: "bg-gray-100"
            )
          ]}>
            <p class="font-semibold text-sm text-gray-600 mb-1">
              {message.user_name}
            </p>
            <p class="text-gray-800">{message.content}</p>
            <p class="text-xs text-gray-500 mt-1">
              {relative_time(message.inserted_at)}
            </p>
          </div>
        </div>
        
        <%= if @loading_more do %>
          <div class="text-center py-2">
            <div class="inline-block animate-spin h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full"></div>
            <span class="ml-2 text-gray-600">메시지 로딩 중...</span>
          </div>
        <% end %>
      </div>

      <!-- 메시지 입력 -->
      <div class="border-t p-4">
        <.form for={@message_form} phx-submit="send_message" class="flex space-x-2">
          <input
            name="content"
            placeholder="메시지를 입력하세요..."
            class="flex-1 px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500"
            phx-hook="MessageInput"
            id="message-input"
          />
          <button
            type="submit"
            class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
          >
            전송
          </button>
        </.form>
      </div>
    </div>
    """
  end

  # 새 메시지 전송
  def handle_event("send_message", %{"content" => content}, socket) do
    if String.trim(content) != "" do
      case Chat.create_message(%{
        content: content,
        user_id: socket.assigns.current_user_id,
        user_name: socket.assigns.current_user_name
      }) do
        {:ok, message} ->
          # 자신의 메시지는 즉시 스트림에 추가
          socket = stream_insert(socket, :messages, message, at: -1)
          
          # 다른 사용자들에게 브로드캐스트
          Phoenix.PubSub.broadcast(
            PhoenixChat.PubSub,
            "messages",
            {:new_message, message}
          )

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "메시지 전송에 실패했습니다.")}
      end
    else
      {:noreply, socket}
    end
  end

  # 이전 메시지 더 불러오기
  def handle_event("load-more-messages", _params, socket) do
    socket = assign(socket, :loading_more, true)
    
    # 비동기적으로 이전 메시지 로드
    Process.send_after(self(), :fetch_older_messages, 500)
    
    {:noreply, socket}
  end

  # 새 메시지 수신 (다른 사용자가 보낸 것)
  def handle_info({:new_message, message}, socket) do
    # 자신이 보낸 메시지가 아닌 경우만 스트림에 추가
    socket = 
      if message.user_id != socket.assigns.current_user_id do
        stream_insert(socket, :messages, message, at: -1)
      else
        socket
      end
    
    {:noreply, socket}
  end

  # 이전 메시지 페치 완료
  def handle_info(:fetch_older_messages, socket) do
    current_message_ids = 
      socket.assigns.streams.messages
      |> Enum.map(fn {_dom_id, message} -> message.id end)
    
    older_messages = Chat.list_messages_before(current_message_ids, 20)
    
    socket = 
      socket
      |> assign(:loading_more, false)
      |> stream(:messages, older_messages, at: 0)  # 맨 앞에 추가

    {:noreply, socket}
  end

  # 헬퍼 함수
  defp relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "방금 전"
      diff < 3600 -> "#{div(diff, 60)}분 전"
      diff < 86400 -> "#{div(diff, 3600)}시간 전"
      true -> "#{div(diff, 86400)}일 전"
    end
  end
end
```

## 🧩 LiveView 컴포넌트 시스템

### 함수 컴포넌트 만들기

```elixir
# lib/phoenix_chat_web/components/chat_components.ex
defmodule PhoenixChatWeb.ChatComponents do
  use Phoenix.Component
  import PhoenixChatWeb.CoreComponents

  @doc """
  메시지 말풍선 컴포넌트
  """
  slot :inner_block, required: true
  attr :user_name, :string, required: true
  attr :timestamp, :any, required: true
  attr :own_message, :boolean, default: false
  attr :class, :string, default: ""

  def message_bubble(assigns) do
    ~H"""
    <div class={[
      "max-w-xs p-3 rounded-lg",
      if(@own_message,
        do: "bg-blue-500 text-white ml-auto",
        else: "bg-gray-200 text-gray-800"
      ),
      @class
    ]}>
      <%= if not @own_message do %>
        <p class="font-semibold text-sm mb-1 opacity-75">{@user_name}</p>
      <% end %>
      
      <div class="break-words">
        {render_slot(@inner_block)}
      </div>
      
      <p class={[
        "text-xs mt-1",
        if(@own_message, do: "text-blue-100", else: "text-gray-500")
      ]}>
        {format_time(@timestamp)}
      </p>
    </div>
    """
  end

  @doc """
  온라인 사용자 표시기
  """
  attr :users, :list, required: true
  attr :class, :string, default: ""

  def online_users(assigns) do
    ~H"""
    <div class={["bg-white rounded-lg shadow p-4", @class]}>
      <h3 class="font-semibold text-gray-800 mb-3">
        온라인 사용자 ({length(@users)})
      </h3>
      
      <div class="space-y-2">
        <%= for user <- @users do %>
          <div class="flex items-center space-x-2">
            <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            <span class="text-sm text-gray-700">{user.name}</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  타이핑 인디케이터
  """
  attr :typing_users, :list, default: []

  def typing_indicator(assigns) do
    ~H"""
    <%= if @typing_users != [] do %>
      <div class="flex items-center space-x-2 p-2 text-sm text-gray-500">
        <div class="flex space-x-1">
          <div class="w-1 h-1 bg-gray-400 rounded-full animate-bounce"></div>
          <div class="w-1 h-1 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.1s"></div>
          <div class="w-1 h-1 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
        </div>
        <span>
          <%= case length(@typing_users) do %>
            <% 1 -> %>
              {List.first(@typing_users)}님이 입력 중...
            <% 2 -> %>
              {Enum.join(@typing_users, ", ")}님이 입력 중...
            <% count when count > 2 -> %>
              {count}명이 입력 중...
          <% end %>
        </span>
      </div>
    <% end %>
    """
  end

  defp format_time(datetime) do
    datetime
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0, 5)  # HH:MM 형식
  end
end
```

### 컴포넌트 사용하기

```elixir
# LiveView에서 컴포넌트 사용
def render(assigns) do
  ~H"""
  <div class="flex h-screen">
    <!-- 사이드바 -->
    <div class="w-64 bg-gray-100 p-4">
      <.online_users users={@online_users} />
    </div>

    <!-- 메인 채팅 영역 -->
    <div class="flex-1 flex flex-col">
      <!-- 메시지 목록 -->
      <div class="flex-1 p-4 space-y-3 overflow-y-auto">
        <%= for message <- @messages do %>
          <.message_bubble 
            user_name={message.user_name}
            timestamp={message.inserted_at}
            own_message={message.user_id == @current_user.id}
          >
            {message.content}
          </.message_bubble>
        <% end %>

        <!-- 타이핑 인디케이터 -->
        <.typing_indicator typing_users={@typing_users} />
      </div>
    </div>
  </div>
  """
end
```

## 🎣 JavaScript Hook 활용

### 클라이언트 사이드 기능 통합

```javascript
// assets/js/hooks.js
const Hooks = {}

// 메시지 입력 시 자동 포커스와 엔터키 처리
Hooks.MessageInput = {
  mounted() {
    this.el.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault()
        // 폼 제출 트리거
        this.el.form.dispatchEvent(new Event('submit', { bubbles: true }))
      }
    })
    
    // 메시지 전송 후 입력창 클리어
    this.handleEvent('clear-input', () => {
      this.el.value = ''
      this.el.focus()
    })
  }
}

// 스크롤 자동 하단 이동
Hooks.MessageContainer = {
  mounted() {
    this.scrollToBottom()
  },

  updated() {
    // 새 메시지가 추가되면 자동으로 스크롤
    this.scrollToBottom()
  },

  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

// 파일 드래그 앤 드롭
Hooks.FileDropZone = {
  mounted() {
    this.el.addEventListener('dragover', (e) => {
      e.preventDefault()
      this.el.classList.add('border-blue-500', 'bg-blue-50')
    })

    this.el.addEventListener('dragleave', (e) => {
      e.preventDefault()
      this.el.classList.remove('border-blue-500', 'bg-blue-50')
    })

    this.el.addEventListener('drop', (e) => {
      e.preventDefault()
      this.el.classList.remove('border-blue-500', 'bg-blue-50')
      
      const files = Array.from(e.dataTransfer.files)
      this.uploadFiles(files)
    })
  },

  uploadFiles(files) {
    // LiveView 업로드 API 사용
    this.upload('files', files)
  }
}

// 실시간 타이핑 감지
Hooks.TypingDetector = {
  mounted() {
    let typingTimer
    
    this.el.addEventListener('input', () => {
      // 타이핑 시작 알림
      this.pushEvent('typing_start', {})
      
      // 이전 타이머 클리어
      clearTimeout(typingTimer)
      
      // 1초 후 타이핑 중지 알림
      typingTimer = setTimeout(() => {
        this.pushEvent('typing_stop', {})
      }, 1000)
    })

    this.el.addEventListener('blur', () => {
      clearTimeout(typingTimer)
      this.pushEvent('typing_stop', {})
    })
  }
}

export default Hooks
```

### app.js에서 Hook 등록

```javascript
// assets/js/app.js
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Hooks from "./hooks"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks  // 여기서 Hook 등록
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation
window.liveSocket = liveSocket
```

### LiveView에서 Hook 사용

```elixir
def render(assigns) do
  ~H"""
  <div class="chat-container">
    <div 
      id="messages" 
      phx-hook="MessageContainer"
      class="messages-list"
    >
      <!-- 메시지들 -->
    </div>

    <form phx-submit="send_message">
      <input
        type="text"
        name="content"
        phx-hook="TypingDetector"
        id="message-input"
        placeholder="메시지를 입력하세요..."
      />
    </form>

    <div 
      phx-hook="FileDropZone"
      class="drop-zone"
    >
      파일을 여기에 드래그하세요
    </div>
  </div>
  """
end

def handle_event("typing_start", _params, socket) do
  # 다른 사용자들에게 타이핑 시작 알림
  broadcast_typing_status(socket, :start)
  {:noreply, socket}
end

def handle_event("typing_stop", _params, socket) do
  # 다른 사용자들에게 타이핑 중지 알림
  broadcast_typing_status(socket, :stop)
  {:noreply, socket}
end
```

## 📁 파일 업로드 구현

### LiveView에서 파일 업로드 설정

```elixir
# lib/phoenix_chat_web/live/chat_room_live.ex
defmodule PhoenixChatWeb.ChatRoomLive do
  use PhoenixChatWeb, :live_view

  def mount(_params, _session, socket) do
    socket = 
      socket
      |> assign(:messages, [])
      |> allow_upload(:files, 
        accept: ~w(.jpg .jpeg .png .pdf .docx),
        max_entries: 5,
        max_file_size: 10_000_000,  # 10MB
        progress: &handle_progress/3,
        auto_upload: true
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="chat-room">
      <!-- 메시지 목록 -->
      <div class="messages">
        <%= for message <- @messages do %>
          <div class="message">
            <%= if message.type == "file" do %>
              <.file_message message={message} />
            <% else %>
              <.text_message message={message} />
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- 파일 업로드 영역 -->
      <form phx-submit="save" phx-change="validate">
        <div class="upload-area">
          <.live_file_input upload={@uploads.files} class="hidden" />
          
          <!-- 드래그 앤 드롭 영역 -->
          <div 
            phx-drop-target={@uploads.files.ref}
            class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-gray-400 transition-colors"
          >
            <div class="space-y-2">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 48 48">
                <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              <div class="text-gray-600">
                <p>파일을 여기에 끌어다 놓거나</p>
                <label class="cursor-pointer text-blue-500 hover:text-blue-600">
                  클릭하여 선택하세요
                  <input type="file" class="sr-only" multiple phx-hook="FileSelect">
                </label>
              </div>
              <p class="text-sm text-gray-500">
                JPG, PNG, PDF, DOCX (최대 10MB, 5개 파일)
              </p>
            </div>
          </div>
        </div>

        <!-- 업로드 진행률 표시 -->
        <%= for entry <- @uploads.files.entries do %>
          <div class="upload-entry">
            <div class="flex items-center justify-between p-3 bg-gray-50 rounded">
              <div class="flex items-center space-x-3">
                <div class="file-icon">
                  <.file_icon type={Path.extname(entry.client_name)} />
                </div>
                <div>
                  <p class="font-medium">{entry.client_name}</p>
                  <p class="text-sm text-gray-500">{format_bytes(entry.client_size)}</p>
                </div>
              </div>
              
              <div class="flex items-center space-x-2">
                <!-- 진행률 바 -->
                <div class="w-32 bg-gray-200 rounded-full h-2">
                  <div 
                    class="bg-blue-500 h-2 rounded-full transition-all duration-300"
                    style={"width: #{entry.progress}%"}
                  ></div>
                </div>
                
                <span class="text-sm font-medium">{entry.progress}%</span>
                
                <!-- 취소 버튼 -->
                <button 
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-red-500 hover:text-red-700"
                >
                  ✕
                </button>
              </div>
            </div>
            
            <!-- 에러 표시 -->
            <%= for err <- upload_errors(@uploads.files, entry) do %>
              <p class="text-red-500 text-sm mt-1">{error_to_string(err)}</p>
            <% end %>
          </div>
        <% end %>

        <!-- 전송 버튼 -->
        <button 
          type="submit"
          disabled={@uploads.files.entries == []}
          class="mt-4 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-300 text-white font-bold py-2 px-4 rounded"
        >
          파일 전송
        </button>
      </form>
    </div>
    """
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        # 파일을 영구 저장소에 복사
        dest = Path.join(["uploads", "#{entry.uuid}-#{entry.client_name}"])
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(path, dest)
        
        # 파일 정보 반환
        {:ok, %{
          original_name: entry.client_name,
          stored_name: dest,
          size: entry.client_size,
          content_type: entry.client_type
        }}
      end)

    # 업로드된 파일들을 메시지로 추가
    Enum.each(uploaded_files, fn file_info ->
      message = %{
        type: "file",
        content: file_info.original_name,
        file_path: file_info.stored_name,
        file_size: file_info.size,
        user_id: socket.assigns.current_user.id,
        user_name: socket.assigns.current_user.name,
        inserted_at: DateTime.utc_now()
      }
      
      # 메시지 브로드캐스트
      Phoenix.PubSub.broadcast(PhoenixChat.PubSub, "chat_room", {:new_message, message})
    end)

    {:noreply, socket}
  end

  defp handle_progress(:files, entry, socket) do
    # 진행률 업데이트 시 추가 로직 (필요한 경우)
    {:noreply, socket}
  end

  # 헬퍼 컴포넌트들
  defp file_icon(assigns) do
    icon_class = case assigns.type do
      ext when ext in [".jpg", ".jpeg", ".png", ".gif"] -> "text-green-500"
      ".pdf" -> "text-red-500"
      ext when ext in [".doc", ".docx"] -> "text-blue-500"
      _ -> "text-gray-500"
    end

    assigns = assign(assigns, :icon_class, icon_class)

    ~H"""
    <div class={["w-8 h-8 rounded flex items-center justify-center", @icon_class]}>
      📎
    </div>
    """
  end

  defp format_bytes(bytes) do
    cond do
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)} KB"
      true -> "#{bytes} bytes"
    end
  end

  defp error_to_string(:too_large), do: "파일 크기가 너무 큽니다"
  defp error_to_string(:not_accepted), do: "지원하지 않는 파일 형식입니다"
  defp error_to_string(:too_many_files), do: "파일 개수가 너무 많습니다"
  defp error_to_string(err), do: "업로드 오류: #{inspect(err)}"
end
```

## 🔍 실시간 검색 구현

### 디바운스된 검색

```elixir
defmodule PhoenixChatWeb.SearchLive do
  use PhoenixChatWeb, :live_view
  alias PhoenixChat.Chat

  def mount(_params, _session, socket) do
    socket = 
      socket
      |> assign(:query, "")
      |> assign(:results, [])
      |> assign(:loading, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-2xl font-bold mb-6">메시지 검색</h1>
      
      <!-- 검색 입력 -->
      <div class="relative mb-6">
        <input
          type="text"
          value={@query}
          placeholder="메시지를 검색하세요..."
          phx-keyup="search_input"
          phx-debounce="300"
          class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
        />
        
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center">
          <%= if @loading do %>
            <div class="animate-spin h-5 w-5 border-2 border-blue-500 border-t-transparent rounded-full"></div>
          <% else %>
            <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>
          <% end %>
        </div>
      </div>

      <!-- 검색 결과 -->
      <div class="space-y-4">
        <%= if @query == "" do %>
          <p class="text-gray-500 text-center py-8">검색어를 입력하세요</p>
        <% else %>
          <%= if @results == [] and not @loading do %>
            <p class="text-gray-500 text-center py-8">검색 결과가 없습니다</p>
          <% else %>
            <%= for message <- @results do %>
              <div class="bg-white border rounded-lg p-4 hover:shadow-md transition-shadow">
                <div class="flex items-start justify-between mb-2">
                  <h3 class="font-semibold text-gray-900">{message.user_name}</h3>
                  <time class="text-sm text-gray-500">
                    {Calendar.strftime(message.inserted_at, "%Y.%m.%d %H:%M")}
                  </time>
                </div>
                <p class="text-gray-700">
                  {highlight_search_term(message.content, @query)}
                </p>
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("search_input", %{"value" => query}, socket) do
    socket = assign(socket, :query, query)

    if String.length(String.trim(query)) >= 2 do
      socket = assign(socket, :loading, true)
      send(self(), {:perform_search, query})
      {:noreply, socket}
    else
      {:noreply, assign(socket, :results, [])}
    end
  end

  def handle_info({:perform_search, query}, socket) do
    # 현재 쿼리와 일치하는 경우만 검색 수행 (사용자가 계속 입력 중일 수 있음)
    if query == socket.assigns.query do
      results = Chat.search_messages(query)
      
      socket = 
        socket
        |> assign(:results, results)
        |> assign(:loading, false)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp highlight_search_term(text, query) do
    if String.length(String.trim(query)) >= 2 do
      highlighted = String.replace(text, query, "<mark>#{query}</mark>", global: true)
      Phoenix.HTML.raw(highlighted)
    else
      text
    end
  end
end
```

## ✅ 실습 과제

### 고급 채팅 기능 구현

다음 기능들을 단계별로 구현해보세요:

1. **메시지 반응 시스템**
   - 이모지 반응 추가/제거
   - 반응 카운트 실시간 업데이트

2. **메시지 편집/삭제**
   - 자신의 메시지만 편집/삭제 가능
   - 편집 이력 표시

3. **멘션 시스템**
   - @username 형태로 사용자 멘션
   - 멘션된 사용자에게 알림

4. **채팅방 관리**
   - 채팅방 생성/삭제
   - 참여자 관리
   - 채팅방별 권한 설정

## 📝 정리

이 장에서 배운 고급 기능들:

### Streams의 장점
- **메모리 효율성**: 대량 데이터 처리 시 메모리 사용량 최적화
- **성능**: 변경된 항목만 DOM 업데이트
- **실시간성**: 새 데이터 추가/수정/삭제가 부드럽게 처리

### 컴포넌트 시스템
- **재사용성**: 공통 UI 패턴을 컴포넌트로 추출
- **유지보수성**: 변경사항을 한 곳에서 관리
- **일관성**: 전체 앱에서 일관된 디자인 제공

### JavaScript Hook
- **클라이언트 통합**: DOM 조작, 외부 라이브러리 통합
- **실시간 UX**: 타이핑 감지, 드래그 앤 드롭 등
- **성능 최적화**: 서버 왕복 없는 클라이언트 로직

### 파일 업로드
- **진행률 표시**: 실시간 업로드 진행률
- **검증**: 파일 타입, 크기 검증
- **에러 처리**: 사용자 친화적 에러 메시지

## 🚀 다음 단계

다음 장에서는 Phoenix Channels와 PubSub을 이용해 본격적인 실시간 채팅 시스템을 구축하겠습니다.

**다음**: [6장 - 기본 채팅 시스템 구현](./06-basic-chat-system.md)