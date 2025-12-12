% ============================================================
%   FAST POKER TRAINER - Instant Stats, No Waiting
%   Simple • Fast • Fun
% ============================================================

clear; clc;

printf("\n╔════════════════════════════════════════╗\n");
printf("║     FAST POKER TRAINER                ║\n");
printf("║     Learn GTO - No Waiting            ║\n");
printf("╚════════════════════════════════════════╝\n\n");

stack = 1000;
bb = 20;
handsPlayed = 0;

% ------------------------------------------------------------
% CARD SETUP
% ------------------------------------------------------------

ranks = {"2","3","4","5","6","7","8","9","T","J","Q","K","A"};
suits = {"s","h","d","c"};

function d = shuffleDeck()
  ranks = {"2","3","4","5","6","7","8","9","T","J","Q","K","A"};
  suits = {"s","h","d","c"};
  deck = {};
  for r = 1:length(ranks)
    for s = 1:length(suits)
      deck{end+1} = [ranks{r} suits{s}];
    endfor
  endfor
  d = deck(randperm(length(deck)));
endfunction


function val = rankVal(r)
  rankMap = containers.Map({'2','3','4','5','6','7','8','9','T','J','Q','K','A'}, 2:14);
  val = rankMap(r);
endfunction


function symbol = suitSymbol(s)
  if s == 's'
    symbol = '♠';
  elseif s == 'h'
    symbol = '♥';
  elseif s == 'd'
    symbol = '♦';
  elseif s == 'c'
    symbol = '♣';
  else
    symbol = s;
  endif
endfunction


function displayCard(card)
  rank = card(1);
  suit = suitSymbol(card(2));
  printf("%c%c", rank, suit);
endfunction


function displayHand(cards)
  for i = 1:length(cards)
    displayCard(cards{i});
    printf(" ");
  endfor
endfunction


% ------------------------------------------------------------
% FAST HAND EVALUATOR
% ------------------------------------------------------------

function [category, value] = evaluateHand(cards)
  if length(cards) < 5
    category = 0;
    value = 0;
    return;
  endif

  ranks = zeros(1, length(cards));
  suits = {};
  for i = 1:length(cards)
    ranks(i) = rankVal(cards{i}(1));
    suits{i} = cards{i}(2);
  endfor

  rankCounts = zeros(1, 15);
  for r = ranks
    rankCounts(r)++;
  endfor

  quads = find(rankCounts == 4);
  trips = find(rankCounts == 3);
  pairs = find(rankCounts == 2);

  % Check flush
  suitCounts = containers.Map();
  for s = suits
    suit = s{1};
    if isKey(suitCounts, suit)
      suitCounts(suit) = suitCounts(suit) + 1;
    else
      suitCounts(suit) = 1;
    endif
  endfor

  isFlush = false;
  for s = {'s','h','d','c'}
    if isKey(suitCounts, s{1}) && suitCounts(s{1}) >= 5
      isFlush = true;
      break;
    endif
  endfor

  % Check straight
  uniqueRanks = unique(ranks);
  isStraight = false;

  for i = 1:(length(uniqueRanks)-4)
    window = uniqueRanks(i:i+4);
    if length(window) == 5 && max(window) - min(window) == 4
      isStraight = true;
    endif
  endfor

  if any(ranks == 14) && any(ranks == 2) && any(ranks == 3) && any(ranks == 4) && any(ranks == 5)
    isStraight = true;
  endif

  % Determine hand
  if isStraight && isFlush
    category = 9;
    value = max(ranks) * 1e10;
  elseif ~isempty(quads)
    category = 8;
    value = max(quads) * 1e10;
  elseif ~isempty(trips) && ~isempty(pairs)
    category = 7;
    value = max(trips) * 1e10 + max(pairs) * 1e8;
  elseif isFlush
    category = 6;
    value = max(ranks) * 1e10;
  elseif isStraight
    category = 5;
    value = max(ranks) * 1e10;
  elseif ~isempty(trips)
    category = 4;
    value = max(trips) * 1e10;
  elseif length(pairs) >= 2
    category = 3;
    sortedPairs = sort(pairs, 'descend');
    value = sortedPairs(1) * 1e10 + sortedPairs(2) * 1e8;
  elseif length(pairs) == 1
    category = 2;
    value = pairs(1) * 1e10 + max(ranks) * 1e8;
  else
    category = 1;
    value = max(ranks) * 1e10;
  endif
endfunction


function name = handName(category)
  names = {"High Card", "Pair", "Two Pair", "Trips", "Straight", "Flush", "Full House", "Quads", "Str Flush"};
  if category >= 1 && category <= 9
    name = names{category};
  else
    name = "Unknown";
  endif
endfunction


% ------------------------------------------------------------
% INSTANT EQUITY ESTIMATION (NO MONTE CARLO)
% ------------------------------------------------------------

function equity = fastEquity(heroHand, board)
  % Instant equity based on hand strength
  [cat, val] = evaluateHand([heroHand, board]);

  % Base equity from hand category
  baseEquities = [0.25, 0.35, 0.50, 0.60, 0.70, 0.75, 0.85, 0.90, 0.95];

  if cat >= 1 && cat <= 9
    equity = baseEquities(cat);
  else
    equity = 0.30;
  endif

  % Adjust for draws if we have flush/straight potential
  if length(board) < 5 && cat <= 2  % Only high card or pair
    heroSuits = {heroHand{1}(2), heroHand{2}(2)};
    boardSuits = {};
    for i = 1:length(board)
      boardSuits{end+1} = board{i}(2);
    endfor

    allSuits = [heroSuits, boardSuits];
    for s = {'s','h','d','c'}
      suitCount = sum(strcmp(allSuits, s{1}));
      if suitCount == 4  % Flush draw
        equity = equity + 0.15;
      endif
    endfor
  endif

  equity = max(0.15, min(0.95, equity));
endfunction


% ------------------------------------------------------------
% GAME LOOP
% ------------------------------------------------------------

printf("Starting stack: $%d | Big Blind: $%d\n\n", stack, bb);

while stack > bb

  handsPlayed++;
  printf("\n");
  printf("════════════════════════════════════════\n");
  printf("  HAND #%d | Stack: $%d\n", handsPlayed, stack);
  printf("════════════════════════════════════════\n\n");

  % Deal cards
  deck = shuffleDeck();
  heroHand = {deck{1}, deck{2}};
  villainHand = {deck{3}, deck{4}};

  % Blinds
  pot = 30;
  stack -= 20;

  printf("Your cards: ");
  displayHand(heroHand);
  printf("\n");

  [preCat, preVal] = evaluateHand(heroHand);
  printf("Preflop hand: %s\n\n", handName(preCat));

  % PREFLOP
  printf("─── PREFLOP ───\n");
  printf("Villain raises to $60\n\n");

  toCall = 40;
  pot += 60;

  equity = fastEquity(heroHand, {});
  potOdds = toCall / (pot + toCall);

  printf("Your equity: ~%.0f%%\n", equity * 100);
  printf("Pot odds: %.0f%% (need this equity to call profitably)\n\n", potOdds * 100);

  if equity >= potOdds
    printf("→ You have enough equity! Calling is +EV\n\n");
  else
    printf("→ Not enough equity - folding is better\n\n");
  endif

  printf("Options:\n");
  printf("  [f] Fold\n");
  printf("  [c] Call $%d\n", toCall);
  printf("  [?] Help\n");
  printf("\nYour choice: ");

  choice = input("", "s");

  if isempty(choice) || choice(1) == 'f' || choice(1) == 'F'
    printf("\nYou folded.\n");
    continue;
  elseif choice(1) == '?'
    printf("\nQuick Guide:\n");
    printf("- If your equity > pot odds → CALL is profitable\n");
    printf("- If your equity < pot odds → FOLD saves money\n");
    printf("- Equity = your chance to win the hand\n");
    printf("- Pot odds = minimum equity needed\n\n");
    input("Press ENTER to continue...");
    continue;
  endif

  stack -= toCall;
  pot += toCall;

  % FLOP
  board = {deck{5}, deck{6}, deck{7}};

  printf("\n");
  printf("─── FLOP ───\n");
  printf("Board: ");
  displayHand(board);
  printf("\n");

  [flopCat, flopVal] = evaluateHand([heroHand, board]);
  printf("Your hand: %s\n\n", handName(flopCat));

  betAmount = round(pot * 0.7);
  printf("Villain bets $%d\n\n", betAmount);

  potBefore = pot;
  pot += betAmount;

  equity = fastEquity(heroHand, board);
  potFacing = potBefore + betAmount;
  potOdds = betAmount / (potFacing + betAmount);
  evCall = equity * potFacing - (1 - equity) * betAmount;

  printf("═══ MATH ═══\n");
  printf("Your equity: ~%.0f%%\n", equity * 100);
  printf("Pot odds: %.0f%%\n", potOdds * 100);
  printf("EV(call): $%.2f\n\n", evCall);

  if evCall > 0
    printf("✓ Calling is +EV (profitable)\n\n");
  else
    printf("✗ Calling is -EV (loses money)\n\n");
  endif

  printf("Options:\n");
  printf("  [f] Fold\n");
  printf("  [c] Call $%d\n", betAmount);
  printf("\nYour choice: ");

  choice = input("", "s");

  if isempty(choice) || choice(1) == 'f' || choice(1) == 'F'
    printf("\nYou folded.\n");
    continue;
  endif

  stack -= betAmount;
  pot += betAmount;

  % TURN
  board{end+1} = deck{8};

  printf("\n");
  printf("─── TURN ───\n");
  printf("Board: ");
  displayHand(board);
  printf("\n");

  [turnCat, turnVal] = evaluateHand([heroHand, board]);
  printf("Your hand: %s\n\n", handName(turnCat));

  betAmount = round(pot * 0.7);
  printf("Villain bets $%d\n\n", betAmount);

  potBefore = pot;
  pot += betAmount;

  equity = fastEquity(heroHand, board);
  potFacing = potBefore + betAmount;
  potOdds = betAmount / (potFacing + betAmount);
  evCall = equity * potFacing - (1 - equity) * betAmount;

  printf("═══ MATH ═══\n");
  printf("Your equity: ~%.0f%%\n", equity * 100);
  printf("Pot odds: %.0f%%\n", potOdds * 100);
  printf("EV(call): $%.2f\n\n", evCall);

  if evCall > 0
    printf("✓ +EV call\n\n");
  else
    printf("✗ -EV call\n\n");
  endif

  printf("Options:\n");
  printf("  [f] Fold\n");
  printf("  [c] Call $%d\n", betAmount);
  printf("\nYour choice: ");

  choice = input("", "s");

  if isempty(choice) || choice(1) == 'f' || choice(1) == 'F'
    printf("\nYou folded.\n");
    continue;
  endif

  stack -= betAmount;
  pot += betAmount;

  % RIVER
  board{end+1} = deck{9};

  printf("\n");
  printf("─── RIVER ───\n");
  printf("Board: ");
  displayHand(board);
  printf("\n");

  [riverCat, riverVal] = evaluateHand([heroHand, board]);
  printf("Your hand: %s\n\n", handName(riverCat));

  % SHOWDOWN
  [villainCat, villainVal] = evaluateHand([villainHand, board]);

  printf("─── SHOWDOWN ───\n");
  printf("Villain: ");
  displayHand(villainHand);
  printf(" (%s)\n", handName(villainCat));
  printf("You:     ");
  displayHand(heroHand);
  printf(" (%s)\n\n", handName(riverCat));

  if riverCat > villainCat || (riverCat == villainCat && riverVal > villainVal)
    printf("*** YOU WIN $%d! ***\n", pot);
    stack += pot;
  elseif villainCat > riverCat || (villainCat == riverCat && villainVal > riverVal)
    printf("Villain wins $%d\n", pot);
  else
    printf("Chop pot - $%d each\n", pot/2);
    stack += pot/2;
  endif

  printf("\nStack: $%d | Hands: %d | P/L: $%d\n", stack, handsPlayed, stack - 1000);

  printf("\n[Enter]=Next hand, Q=Quit: ");
  choice = input("", "s");
  if ~isempty(choice) && (choice(1) == 'Q' || choice(1) == 'q')
    break;
  endif

endwhile

printf("\n");
printf("═══════════════════════════════════════\n");
printf("  SESSION COMPLETE\n");
printf("═══════════════════════════════════════\n");
printf("Hands: %d | Final: $%d | P/L: $%d\n", handsPlayed, stack, stack - 1000);
printf("\nThanks for playing!\n\n");
