-- Enums
CREATE TYPE "public"."gf_SavingsKind"   AS ENUM ('FIXED','VARIABLE','PRIME_PLUS_MINUS');
CREATE TYPE "public"."gf_BaseIndex"     AS ENUM ('P','CPI','EURIBOR','SOFR');
CREATE TYPE "public"."gf_Compounding"   AS ENUM ('NONE','MONTHLY','YEARLY');
CREATE TYPE "public"."gf_SavingsTxKind" AS ENUM ('DEPOSIT','WITHDRAWAL','INTEREST','ADJUSTMENT');
CREATE TYPE "public"."gf_Frequency"     AS ENUM ('WEEKLY','MONTHLY','QUARTERLY');
CREATE TYPE "public"."gf_LotMethod"     AS ENUM ('FIFO','SPECIFIC_ID');

-- Tables
CREATE TABLE "public"."gf_SavingsAccount" (
  "id"           TEXT        NOT NULL,
  "userId"       TEXT        NOT NULL,
  "name"         TEXT        NOT NULL,
  "kind"         "public"."gf_SavingsKind"   NOT NULL,
  "annualRateBps" INTEGER,
  "baseIndex"    "public"."gf_BaseIndex",
  "marginBps"    INTEGER,
  "compounding"  "public"."gf_Compounding"   NOT NULL DEFAULT 'MONTHLY',
  "currency"     TEXT        DEFAULT 'ILS',
  "isActive"     BOOLEAN     NOT NULL DEFAULT TRUE,
  "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "gf_SavingsAccount_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "public"."gf_SavingsTx" (
  "id"         TEXT        NOT NULL,
  "accountId"  TEXT        NOT NULL,
  "date"       TIMESTAMP(3) NOT NULL,
  "kind"       "public"."gf_SavingsTxKind" NOT NULL,
  "amount"     DECIMAL(18,4) NOT NULL,
  "note"       TEXT,
  "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "gf_SavingsTx_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "public"."gf_RecurringDeposit" (
  "id"         TEXT        NOT NULL,
  "accountId"  TEXT        NOT NULL,
  "amount"     DECIMAL(18,4) NOT NULL,
  "frequency"  "public"."gf_Frequency" NOT NULL,
  "dayOfMonth" INTEGER,
  "weekday"    INTEGER,
  "startDate"  TIMESTAMP(3) NOT NULL,
  "endDate"    TIMESTAMP(3),
  "nextRunAt"  TIMESTAMP(3) NOT NULL,
  "isActive"   BOOLEAN     NOT NULL DEFAULT TRUE,
  CONSTRAINT "gf_RecurringDeposit_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "public"."gf_TaxSettings" (
  "id"             TEXT        NOT NULL,
  "userId"         TEXT        NOT NULL,
  "country"        TEXT        NOT NULL DEFAULT 'IL',
  "rateBps"        INTEGER     NOT NULL DEFAULT 2500,
  "includeFees"    BOOLEAN     NOT NULL DEFAULT TRUE,
  "treatDividends" BOOLEAN     NOT NULL DEFAULT TRUE,
  "lotMethod"      "public"."gf_LotMethod" NOT NULL DEFAULT 'FIFO',
  "updatedAt"      TIMESTAMP(3) NOT NULL,
  CONSTRAINT "gf_TaxSettings_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "public"."gf_TaxLot" (
  "id"         TEXT         NOT NULL,
  "userId"     TEXT         NOT NULL,
  "symbol"     TEXT         NOT NULL,
  "quantity"   DECIMAL(18,4) NOT NULL,
  "costBasis"  DECIMAL(18,4) NOT NULL,
  "acquiredAt" TIMESTAMP(3)  NOT NULL,
  "lotRef"     TEXT,
  "isClosed"   BOOLEAN       NOT NULL DEFAULT FALSE,
  "closedAt"   TIMESTAMP(3),
  CONSTRAINT "gf_TaxLot_pkey" PRIMARY KEY ("id")
);

-- Indexes
CREATE INDEX "gf_SavingsTx_accountId_date_idx"
  ON "public"."gf_SavingsTx" ("accountId","date");

CREATE INDEX "gf_RecurringDeposit_accountId_isActive_idx"
  ON "public"."gf_RecurringDeposit" ("accountId","isActive");

CREATE UNIQUE INDEX "gf_TaxSettings_userId_key"
  ON "public"."gf_TaxSettings" ("userId");

CREATE INDEX "gf_TaxLot_userId_symbol_isClosed_idx"
  ON "public"."gf_TaxLot" ("userId","symbol","isClosed");

-- FKs
ALTER TABLE "public"."gf_SavingsTx"
  ADD CONSTRAINT "gf_SavingsTx_accountId_fkey"
  FOREIGN KEY ("accountId") REFERENCES "public"."gf_SavingsAccount"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "public"."gf_RecurringDeposit"
  ADD CONSTRAINT "gf_RecurringDeposit_accountId_fkey"
  FOREIGN KEY ("accountId") REFERENCES "public"."gf_SavingsAccount"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;
