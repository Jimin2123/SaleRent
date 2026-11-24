-- Prisma 스키마로 표현할 수 없는 CHECK 제약.
-- `npx prisma migrate dev --create-only --name init_user_account` 로 생성된
-- migration.sql 맨 아래에 붙여 넣은 뒤 `npx prisma migrate dev` 로 적용.

-- 탈퇴 상태와 탈퇴 일시는 항상 함께
ALTER TABLE "users"
  ADD CONSTRAINT "ck_users_withdrawn"
  CHECK (("status" = 'WITHDRAWN') = ("withdrawn_at" IS NOT NULL));

-- LOCAL이면 비밀번호 필수, 소셜이면 비밀번호 금지
ALTER TABLE "accounts"
  ADD CONSTRAINT "ck_accounts_password"
  CHECK (("provider" = 'LOCAL') = ("password_hash" IS NOT NULL));

-- LOCAL 로그인 ID는 소문자만 (대소문자 중복 가입 방지)
ALTER TABLE "accounts"
  ADD CONSTRAINT "ck_accounts_local_id_lower"
  CHECK ("provider" <> 'LOCAL' OR "provider_user_id" = lower("provider_user_id"));
