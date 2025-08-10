# 3장 - Phoenix 기본 개념과 MVC 패턴

## 🎯 학습 목표

- Phoenix의 MVC + Context 아키텍처 이해
- Context의 개념과 사용법 학습
- Controller, View, Template의 역할과 관계 파악
- 실제 예제를 통한 CRUD 기능 구현
- Ecto를 이용한 데이터베이스 조작 기초

## 🏗️ Phoenix 아키텍처: MVC + Context

### 전통적인 MVC vs Phoenix

#### 전통적인 MVC
```
Controller → Model → Database
     ↓
   View
```

#### Phoenix의 MVC + Context
```
Controller → Context → Schema → Database
     ↓          ↓
   View    (비즈니스 로직)
```

### Context란?

Context는 Phoenix 1.3에서 도입된 개념으로, 관련된 기능들을 그룹화하는 경계(boundary)입니다.

- **목적**: 비즈니스 로직을 웹 계층에서 분리
- **장점**: 테스트 가능성, 재사용성, 유지보수성 향상
- **구조**: 퍼블릭 API를 통해 내부 구현 숨김

## 📊 실습: 사용자 관리 시스템 만들기

### 1. Context와 Schema 생성

```bash
# Accounts Context와 User Schema 생성
mix phx.gen.context Accounts User users \
  name:string \
  email:string:unique \
  bio:text \
  inserted_at:utc_datetime \
  updated_at:utc_datetime
```

이 명령어는 다음 파일들을 생성합니다:

- `lib/phoenix_chat/accounts.ex` (Context)
- `lib/phoenix_chat/accounts/user.ex` (Schema)
- `priv/repo/migrations/xxx_create_users.exs` (Migration)
- `test/phoenix_chat/accounts_test.exs` (Context Test)

### 2. 마이그레이션 실행

```bash
mix ecto.migrate
```

### 3. 생성된 파일들 살펴보기

#### Schema 파일 (`lib/phoenix_chat/accounts/user.ex`)

```elixir
defmodule PhoenixChat.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :bio, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio])
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:bio, max: 500)
  end
end
```

#### Context 파일 (`lib/phoenix_chat/accounts.ex`)

```elixir
defmodule PhoenixChat.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias PhoenixChat.Repo
  alias PhoenixChat.Accounts.User

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.
  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
```

## 🌐 웹 계층 구현

### 1. HTML 컨트롤러와 뷰 생성

```bash
# HTML 인터페이스 생성
mix phx.gen.html Accounts User users \
  name:string email:string bio:text --no-context --no-schema
```

`--no-context --no-schema` 플래그는 이미 생성된 Context와 Schema를 재사용하기 위함입니다.

### 2. 라우터에 경로 추가

```elixir
# lib/phoenix_chat_web/router.ex
scope "/", PhoenixChatWeb do
  pipe_through :browser

  get "/", PageController, :home
  get "/about", PageController, :about
  
  # 사용자 관리 경로 추가
  resources "/users", UserController
end
```

### 3. 컨트롤러 구조 이해

```elixir
# lib/phoenix_chat_web/controllers/user_controller.ex
defmodule PhoenixChatWeb.UserController do
  use PhoenixChatWeb, :controller

  alias PhoenixChat.Accounts
  alias PhoenixChat.Accounts.User

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: ~p"/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: ~p"/users/#{user}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: ~p"/users")
  end
end
```

## 🎨 템플릿 시스템 이해

### HEEx (HTML + Elixir eXtensions)

Phoenix 1.6+에서는 `.html.heex` 확장자를 사용하여 더 안전하고 성능이 좋은 템플릿을 작성합니다.

#### 사용자 목록 템플릿 예제

```heex
<!-- lib/phoenix_chat_web/controllers/user_html/index.html.heex -->
<.header>
  사용자 목록
  <:actions>
    <.link href={~p"/users/new"} class="btn btn-primary">
      새 사용자 추가
    </.link>
  </:actions>
</.header>

<div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
  <table class="min-w-full divide-y divide-gray-300">
    <thead class="bg-gray-50">
      <tr>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
          이름
        </th>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
          이메일
        </th>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
          소개
        </th>
        <th class="relative px-6 py-3">
          <span class="sr-only">작업</span>
        </th>
      </tr>
    </thead>
    <tbody class="bg-white divide-y divide-gray-200">
      <%= for user <- @users do %>
        <tr>
          <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
            {user.name}
          </td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
            {user.email}
          </td>
          <td class="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">
            {user.bio || "소개가 없습니다"}
          </td>
          <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
            <.link href={~p"/users/#{user}"} class="text-blue-600 hover:text-blue-900 mr-2">
              보기
            </.link>
            <.link href={~p"/users/#{user}/edit"} class="text-indigo-600 hover:text-indigo-900 mr-2">
              수정
            </.link>
            <.link 
              href={~p"/users/#{user}"} 
              method="delete" 
              data-confirm="정말 삭제하시겠습니까?"
              class="text-red-600 hover:text-red-900"
            >
              삭제
            </.link>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>

<%= if @users == [] do %>
  <div class="text-center py-12">
    <p class="text-gray-500">아직 등록된 사용자가 없습니다.</p>
    <.link href={~p"/users/new"} class="mt-4 btn btn-primary">
      첫 사용자 추가하기
    </.link>
  </div>
<% end %>
```

#### 사용자 폼 템플릿 예제

```heex
<!-- lib/phoenix_chat_web/controllers/user_html/form.html.heex -->
<.simple_form for={@changeset} action={@action}>
  <.error :if={@changeset.action}>
    저장하는 중에 오류가 발생했습니다. 아래 오류를 확인해주세요.
  </.error>
  
  <.input field={@changeset[:name]} type="text" label="이름" placeholder="홍길동" required />
  <.input field={@changeset[:email]} type="email" label="이메일" placeholder="hong@example.com" required />
  <.input field={@changeset[:bio]} type="textarea" label="소개" placeholder="자기소개를 작성해주세요" rows="4" />
  
  <:actions>
    <.button>사용자 저장</.button>
  </:actions>
</.simple_form>
```

## 🧪 Ecto와 데이터베이스 작업

### 1. IEx에서 Context 테스트하기

```bash
iex -S mix
```

```elixir
# 사용자 생성
alias PhoenixChat.Accounts

{:ok, user} = Accounts.create_user(%{
  name: "김철수",
  email: "kim@example.com", 
  bio: "Phoenix 개발을 배우고 있습니다."
})

# 사용자 목록 조회
users = Accounts.list_users()

# 특정 사용자 조회
user = Accounts.get_user!(1)

# 사용자 업데이트
{:ok, updated_user} = Accounts.update_user(user, %{bio: "Phoenix 고급 기능을 학습 중입니다."})

# 사용자 삭제
{:ok, deleted_user} = Accounts.delete_user(user)
```

### 2. 고급 쿼리 작성

Context에 커스텀 쿼리 함수 추가:

```elixir
# lib/phoenix_chat/accounts.ex에 추가
defmodule PhoenixChat.Accounts do
  # ... 기존 코드 ...

  @doc """
  이메일로 사용자 찾기
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  이름으로 사용자 검색
  """
  def search_users_by_name(name) do
    name_pattern = "%#{name}%"
    
    User
    |> where([u], ilike(u.name, ^name_pattern))
    |> order_by([u], u.name)
    |> Repo.all()
  end

  @doc """
  최근 가입한 사용자들 (최대 10명)
  """
  def get_recent_users(limit \\ 10) do
    User
    |> order_by([u], desc: u.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  사용자 수 카운트
  """
  def count_users do
    User
    |> select([u], count(u.id))
    |> Repo.one()
  end
end
```

### 3. 컨트롤러에서 활용

```elixir
# lib/phoenix_chat_web/controllers/user_controller.ex에 추가
def search(conn, %{"q" => query}) do
  users = Accounts.search_users_by_name(query)
  render(conn, :index, users: users)
end

def recent(conn, _params) do
  users = Accounts.get_recent_users(5)
  render(conn, :index, users: users)
end
```

## 🔧 폼과 Changeset 고급 활용

### 1. 커스텀 검증 추가

```elixir
# lib/phoenix_chat/accounts/user.ex에 추가
defmodule PhoenixChat.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :bio, :string
    field :age, :integer, virtual: true  # 가상 필드

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:bio, max: 500)
    |> validate_age()
    |> unique_constraint(:email)
  end

  defp validate_age(changeset) do
    case get_field(changeset, :age) do
      nil -> changeset
      age when is_integer(age) and age >= 13 and age <= 120 -> changeset
      _ -> add_error(changeset, :age, "나이는 13세 이상 120세 이하여야 합니다")
    end
  end
end
```

### 2. 조건부 검증

```elixir
def registration_changeset(user, attrs) do
  user
  |> changeset(attrs)
  |> validate_required([:bio])  # 등록 시에만 소개 필수
  |> put_change(:email, String.downcase(attrs["email"] || ""))
end
```

## 🧪 실습: 사용자 프로필 시스템

### 1. 프로필 페이지 만들기

```elixir
# lib/phoenix_chat_web/controllers/user_controller.ex에 추가
def profile(conn, %{"id" => id}) do
  user = Accounts.get_user!(id)
  recent_activity = get_user_recent_activity(user)  # 나중에 구현
  
  render(conn, :profile, user: user, recent_activity: recent_activity)
end

defp get_user_recent_activity(_user) do
  # 임시로 빈 배열 반환
  []
end
```

### 2. 프로필 템플릿

```heex
<!-- lib/phoenix_chat_web/controllers/user_html/profile.html.heex -->
<div class="max-w-4xl mx-auto">
  <!-- 사용자 헤더 -->
  <div class="bg-white shadow rounded-lg p-6 mb-6">
    <div class="flex items-center">
      <div class="w-20 h-20 bg-gray-300 rounded-full flex items-center justify-center text-2xl font-bold text-gray-600">
        {String.at(@user.name, 0)}
      </div>
      <div class="ml-6">
        <h1 class="text-3xl font-bold text-gray-900">{@user.name}</h1>
        <p class="text-gray-600">{@user.email}</p>
        <p class="text-sm text-gray-500">
          가입일: {Calendar.strftime(@user.inserted_at, "%Y년 %m월 %d일")}
        </p>
      </div>
      <div class="ml-auto">
        <.link href={~p"/users/#{@user}/edit"} class="btn btn-primary">
          프로필 수정
        </.link>
      </div>
    </div>
    
    <%= if @user.bio do %>
      <div class="mt-4 pt-4 border-t">
        <h3 class="font-semibold mb-2">소개</h3>
        <p class="text-gray-700">{@user.bio}</p>
      </div>
    <% end %>
  </div>

  <!-- 활동 내역 (나중에 구현) -->
  <div class="bg-white shadow rounded-lg p-6">
    <h2 class="text-xl font-bold mb-4">최근 활동</h2>
    <p class="text-gray-500">아직 활동이 없습니다.</p>
  </div>
</div>
```

### 3. 라우트 추가

```elixir
# lib/phoenix_chat_web/router.ex에 추가
resources "/users", UserController do
  get "/profile", UserController, :profile, as: :profile
end
```

## ✅ 이해도 점검

### Context 관련 질문

1. Context의 주요 목적은 무엇인가요?
2. Context와 Schema의 차이점은?
3. 왜 Controller에서 직접 Repo를 사용하지 않나요?

### MVC 관련 질문

1. Controller의 주요 역할은?
2. View 모듈은 어떤 역할을 하나요?
3. Template에서 비즈니스 로직을 작성하면 안 되는 이유는?

### 실습 과제

다음 기능을 직접 구현해보세요:

```elixir
# 1. 사용자 통계 함수
def get_user_stats do
  %{
    total_users: count_users(),
    recent_users: count_recent_users(7), # 7일 이내
    top_users: get_top_users_by_activity() # 나중에 구현
  }
end

# 2. 이메일 중복 검사
def email_taken?(email) do
  # 구현해보세요
end

# 3. 사용자 검색 (이름과 이메일 모두)
def search_users(query) do
  # 구현해보세요
end
```

## 📝 정리

이 장에서 배운 핵심 내용:

- **Context**: 비즈니스 로직의 경계, 관련 기능 그룹화
- **Schema**: 데이터 구조 정의, Changeset으로 데이터 검증
- **Controller**: HTTP 요청 처리, Context 호출, 응답 생성
- **View & Template**: 데이터 표시, HEEx로 안전한 템플릿
- **Ecto**: 데이터베이스 쿼리, 마이그레이션 관리

### 아키텍처 패턴 정리

```
요청 흐름:
Browser → Router → Controller → Context → Schema → Database
                     ↓
                   View → Template → Response
```

### 핵심 원칙

1. **관심사의 분리**: 각 레이어는 고유한 책임을 가짐
2. **Context 경계**: 비즈니스 로직을 웹 계층에서 분리
3. **데이터 검증**: Changeset으로 안전한 데이터 처리
4. **재사용성**: Context는 여러 웹 인터페이스에서 사용 가능

## 🚀 다음 단계

다음 장에서는 Phoenix LiveView의 기초를 학습하여 실시간 상호작용을 구현해보겠습니다.

**다음**: [4장 - LiveView 시작하기](./04-liveview-basics.md)