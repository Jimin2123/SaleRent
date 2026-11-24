-- Prisma 스키마로 표현할 수 없는 제약 (Company / CompanyMember / CompanyInvitation).
-- `npx prisma migrate dev --create-only --name add_company` 로 생성된
-- migration.sql 맨 아래에 붙여 넣은 뒤 `npx prisma migrate dev` 로 적용.

-- 사업자등록번호는 숫자 10자리
ALTER TABLE "companies"
  ADD CONSTRAINT "ck_companies_biz_reg_no"
  CHECK ("biz_reg_no" ~ '^[0-9]{10}$');

-- 인증된 사업자등록번호만 중복 금지
CREATE UNIQUE INDEX "uk_companies_verified_biz_reg_no"
  ON "companies" ("biz_reg_no")
  WHERE "biz_verified_at" IS NOT NULL AND "status" <> 'CLOSED';

-- 퇴사 상태와 퇴사 일시는 항상 함께
ALTER TABLE "company_members"
  ADD CONSTRAINT "ck_company_members_left"
  CHECK (("status" = 'LEFT') = ("left_at" IS NOT NULL));

-- OWNER로는 초대할 수 없음 (OWNER는 위임으로만)
ALTER TABLE "company_invitations"
  ADD CONSTRAINT "ck_company_invitations_role"
  CHECK ("role" <> 'OWNER');

-- 초대 이메일은 소문자만
ALTER TABLE "company_invitations"
  ADD CONSTRAINT "ck_company_invitations_email_lower"
  CHECK ("invitee_email" = lower("invitee_email"));

-- 수락 상태면 수락 일시와 수락자가 반드시 있음
ALTER TABLE "company_invitations"
  ADD CONSTRAINT "ck_company_invitations_accepted"
  CHECK (
    ("status" = 'ACCEPTED' AND "accepted_at" IS NOT NULL AND "accepted_by_user_id" IS NOT NULL)
    OR
    ("status" <> 'ACCEPTED' AND "accepted_at" IS NULL AND "accepted_by_user_id" IS NULL)
  );