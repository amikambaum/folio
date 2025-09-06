$ErrorActionPreference = 'Stop'
$path = "prisma\schema.prisma"

if (-not (Test-Path $path)) { throw "schema.prisma not found at $path" }

# 1) Remove UTF8 BOM if present, read as text
$bytes = [IO.File]::ReadAllBytes($path)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
  $bytes = $bytes[3..($bytes.Length-1)]
}
$text = [Text.Encoding]::UTF8.GetString($bytes)

# 2) Remove any previous inserted gf block by markers (BEGIN..END), even if END missing
$text = [regex]::Replace($text, '(?s)//\s*===\s*gf:\s*savings.*?BEGIN.*?===.*?(//\s*===\s*gf:\s*savings.*?END.*?===)?', '')

# 3) Aggressively remove any loose/malformed gf_* enums/models that might remain
$patterns = @(
  '(?s)enum\s+gf_[A-Za-z0-9_]+\s*\{[^}]*\}',   # remove until first }
  '(?s)model\s+gf_[A-Za-z0-9_]+\s*\{[^}]*\}'
)
foreach ($p in $patterns) {
  $text = [regex]::Replace($text, $p, '')
}

# 4) Compact excessive blank lines
$text = [regex]::Replace($text, "(\r?\n){3,}", "`r`n`r`n").TrimEnd()

# 5) Append a fresh, valid gf_* block (with markers)
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

if ($text -ne '') { $text += "`r`n`r`n" }
$text += $gfBlock + "`r`n"

# 6) Save UTF-8 *without BOM*
$enc = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($path, $text, $enc)

Write-Host "schema.prisma repaired (UTF-8 no BOM) and gf_* block appended."
