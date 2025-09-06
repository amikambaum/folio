$ErrorActionPreference = 'Stop'
$schema = "prisma\schema.prisma"

if (-not (Test-Path $schema)) {
  throw "schema.prisma not found at $schema"
}

# Valid gf_* block to append once
$gfBlock = @'
// === gf: savings & tax (BEGIN) ===
enum gf_SavingsKind { FIXED VARIABLE PRIME_PLUS_MINUS }
enum gf_BaseIndex { P CPI EURIBOR SOFR }
enum gf_Compounding { NONE MONTHLY YEARLY }
enum gf_SavingsTxKind { DEPOSIT WITHDRAWAL INTEREST ADJUSTMENT }
enum gf_Frequency { WEEKLY MONTHLY QUARTERLY }
enum gf_LotMethod { FIFO SPECIFIC_ID }

model gf_SavingsAccount {
  id             String              @id @default(cuid())
  userId         String              @index
  name           String
  kind           gf_SavingsKind
  annualRateBps  Int?
  baseIndex      gf_BaseIndex?
  marginBps      Int?
  compounding    gf_Compounding      @default(MONTHLY)
  currency       String?             @default("ILS")
  isActive       Boolean             @default(true)
  createdAt      DateTime            @default(now())
  tx             gf_SavingsTx[]
  recurringRules gf_RecurringDeposit[]
}

model gf_SavingsTx {
  id        String            @id @default(cuid())
  accountId String
  date      DateTime
  kind      gf_SavingsTxKind
  amount    Decimal           @db.Decimal(18, 4)
  note      String?
  createdAt DateTime          @default(now())
  account   gf_SavingsAccount @relation(fields: [accountId], references: [id])

  @@index([accountId, date])
}

model gf_RecurringDeposit {
  id         String       @id @default(cuid())
  accountId  String
  amount     Decimal      @db.Decimal(18, 4)
  frequency  gf_Frequency
  dayOfMonth Int?
  weekday    Int?
  startDate  DateTime
  endDate    DateTime?
  nextRunAt  DateTime
  isActive   Boolean      @default(true)

  account    gf_SavingsAccount @relation(fields: [accountId], references: [id])

  @@index([accountId, isActive])
}

model gf_TaxSettings {
  id             String       @id @default(cuid())
  userId         String       @unique
  country        String       @default("IL")
  rateBps        Int          @default(2500)
  includeFees    Boolean      @default(true)
  treatDividends Boolean      @default(true)
  lotMethod      gf_LotMethod @default(FIFO)
  updatedAt      DateTime     @updatedAt
}

model gf_TaxLot {
  id         String   @id @default(cuid())
  userId     String
  symbol     String
  quantity   Decimal  @db.Decimal(18, 4)
  costBasis  Decimal  @db.Decimal(18, 4)
  acquiredAt DateTime
  lotRef     String?
  isClosed   Boolean  @default(false)
  closedAt   DateTime?

  @@index([userId, symbol, isClosed])
}
// === gf: savings & tax (END) ===
'@

# Read schema (UTF-8), remove any existing gf_* enums/models, then append once
$raw = Get-Content -Raw -Encoding UTF8 $schema

$patterns = @(
  '(?s)enum\s+gf_SavingsKind\s*\{.*?\}',
  '(?s)enum\s+gf_BaseIndex\s*\{.*?\}',
  '(?s)enum\s+gf_Compounding\s*\{.*?\}',
  '(?s)enum\s+gf_SavingsTxKind\s*\{.*?\}',
  '(?s)enum\s+gf_Frequency\s*\{.*?\}',
  '(?s)enum\s+gf_LotMethod\s*\{.*?\}',
  '(?s)model\s+gf_SavingsAccount\s*\{.*?\}',
  '(?s)model\s+gf_SavingsTx\s*\{.*?\}',
  '(?s)model\s+gf_RecurringDeposit\s*\{.*?\}',
  '(?s)model\s+gf_TaxSettings\s*\{.*?\}',
  '(?s)model\s+gf_TaxLot\s*\{.*?\}'
)

foreach ($p in $patterns) {
  $raw = [regex]::Replace($raw, $p, '', 'Singleline, IgnoreCase')
}

$raw = $raw.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $gfBlock + [Environment]::NewLine
[IO.File]::WriteAllText($schema, $raw, [Text.Encoding]::UTF8)

Write-Host "schema.prisma updated successfully"
