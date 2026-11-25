-- Prisma 스키마로 표현할 수 없는 제약 (품목 / 자산 / 재고 도메인).
-- `npx prisma migrate dev --create-only --name add_product` 로 생성된
-- migration.sql 맨 아래에 붙여 넣은 뒤 `npx prisma migrate dev` 로 적용.
-- PostgreSQL 15 이상 필요 (NULLS NOT DISTINCT).

-- ---------------------------------------------------------------
-- product_categories
-- ---------------------------------------------------------------

-- 같은 회사, 같은 상위 분류 안에서 이름 중복 금지 (대분류끼리도 적용되도록 NULL을 같은 값으로 취급)
CREATE UNIQUE INDEX "uk_product_categories_company_parent_name"
  ON "product_categories" ("company_id", "parent_id", "name") NULLS NOT DISTINCT;

-- 자기 자신을 상위로 지정 금지
ALTER TABLE "product_categories"
  ADD CONSTRAINT "ck_product_categories_not_self_parent"
  CHECK ("parent_id" IS NULL OR "parent_id" <> "id");

-- ---------------------------------------------------------------
-- products
-- ---------------------------------------------------------------

-- 서비스 품목만 실물 없음(NONE)
ALTER TABLE "products"
  ADD CONSTRAINT "ck_products_service_tracking"
  CHECK (("product_type" = 'SERVICE') = ("tracking_type" = 'NONE'));

-- 렌탈은 한 대씩 관리하는 품목만 (계약에 Asset을 배정해야 하므로)
ALTER TABLE "products"
  ADD CONSTRAINT "ck_products_rentable_serial"
  CHECK (NOT "is_rentable" OR "tracking_type" = 'SERIAL');

-- 판매도 렌탈도 안 되는 품목 금지
ALTER TABLE "products"
  ADD CONSTRAINT "ck_products_has_usage"
  CHECK ("is_rentable" OR "is_sellable");

-- 금액은 0 이상
-- (렌탈 요금제 모델 추가 시 default_monthly_rent / product_rental_plans 제약도 함께 추가)
ALTER TABLE "products"
  ADD CONSTRAINT "ck_products_default_sale_price"
  CHECK ("default_sale_price" IS NULL OR "default_sale_price" >= 0);

-- ---------------------------------------------------------------
-- assets
-- ---------------------------------------------------------------

ALTER TABLE "assets"
  ADD CONSTRAINT "ck_assets_purchase_price"
  CHECK ("purchase_price" IS NULL OR "purchase_price" >= 0);

-- ---------------------------------------------------------------
-- asset_status_histories
-- ---------------------------------------------------------------

-- 같은 상태로의 이력 금지
ALTER TABLE "asset_status_histories"
  ADD CONSTRAINT "ck_asset_status_histories_changed"
  CHECK ("from_status" IS NULL OR "from_status" <> "to_status");

-- 정정 이력이 자기 자신을 취소 대상으로 지정 금지
ALTER TABLE "asset_status_histories"
  ADD CONSTRAINT "ck_asset_status_histories_not_self_revert"
  CHECK ("reverts_id" IS NULL OR "reverts_id" <> "id");

-- ---------------------------------------------------------------
-- inventory_stocks / stock_movements
-- ---------------------------------------------------------------

-- 재고는 음수 불가
ALTER TABLE "inventory_stocks"
  ADD CONSTRAINT "ck_inventory_stocks_non_negative"
  CHECK ("quantity" >= 0);

-- 0개 이동 금지
ALTER TABLE "stock_movements"
  ADD CONSTRAINT "ck_stock_movements_non_zero"
  CHECK ("quantity_delta" <> 0);

-- 사유와 방향(+/-) 일치 (실사 조정만 양방향)
ALTER TABLE "stock_movements"
  ADD CONSTRAINT "ck_stock_movements_direction"
  CHECK (
    ("reason" IN ('PURCHASE', 'SALE_RETURN') AND "quantity_delta" > 0) OR
    ("reason" IN ('SALE', 'DISPOSAL')        AND "quantity_delta" < 0) OR
    ("reason" = 'ADJUSTMENT')
  );
