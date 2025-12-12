% ============================================================
%   TRUE GTO POKER TRAINER - Mathematically Correct
%   Real equity • Range-based analysis • Proper EV • GTO strategy
% ============================================================

clear; clc;

printf("\n");
printf("╔════════════════════════════════════════════════╗\n");
printf("║     TRUE GTO POKER TRAINER                    ║\n");
printf("║     Mathematically Correct Poker Education    ║\n");
printf("╚════════════════════════════════════════════════╝\n\n");

% ------------------------------------------------------------
% CARD DEFINITIONS
% ------------------------------------------------------------

ranks = {"2","3","4","5","6","7","8","9","T","J","Q","K","A"};
suits = {"s","h","d","c"};  % spades, hearts, diamonds, clubs

% Build full deck
deck = {};
for r = 1:length(ranks)
  for s = 1:length(suits)
    deck{end+1} = [ranks{r} suits{s}];
  endfor
endfor


% ------------------------------------------------------------
% DISPLAY FUNCTIONS
% ------------------------------------------------------------

function symbol = suitSymbol(s)
  % Convert s,h,d,c to suit symbols
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
  % Display card with proper suit symbol
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
% MAIN MENU
% ------------------------------------------------------------

function choice = showMenu()
  printf("\n");
  printf("┌────────────────────────────────────────┐\n");
  printf("│         TRAINING MENU                  │\n");
  printf("└────────────────────────────────────────┘\n\n");
  printf("  [1] Beginner Mode - Learn pot odds & equity\n");
  printf("  [2] Intermediate - GTO ranges & decisions\n");
  printf("  [3] Advanced - Full GTO analysis\n");
  printf("  [4] Quick Practice - Random hands\n");
  printf("  [5] Settings\n");
  printf("  [Q] Quit\n\n");

  printf("Choose option: ");
  choice = input("", "s");

  if isempty(choice)
    choice = "1";
  endif
endfunction


function settings = showSettings()
  printf("\n");
  printf("┌────────────────────────────────────────┐\n");
  printf("│         SETTINGS                       │\n");
  printf("└────────────────────────────────────────┘\n\n");

  printf("Monte Carlo simulations (for Intermediate/Advanced):\n");
  printf("  [1] Fast    (200 sims)\n");
  printf("  [2] Normal  (500 sims) [Default]\n");
  printf("  [3] Precise (1000 sims)\n");
  printf("\nNote: Beginner mode uses simplified equity for speed\n\n");

  printf("Choose: ");
  simChoice = input("", "s");

  if strcmp(simChoice, "1")
    settings.numSims = 200;
  elseif strcmp(simChoice, "3")
    settings.numSims = 1000;
  else
    settings.numSims = 500;
  endif

  printf("\nStarting stack:\n");
  printf("Stack size (default 1000): $");
  stackInput = input("");
  if isempty(stackInput) || stackInput <= 0
    settings.stack = 1000;
  else
    settings.stack = stackInput;
  endif

  printf("\nSettings saved!\n");
  input("Press ENTER to continue...");
endfunction


% ------------------------------------------------------------
% HAND EVALUATOR - Returns comparable numeric value
% ------------------------------------------------------------

function d = shuffleDeck(deck)
  d = deck(randperm(length(deck)));
endfunction


function val = rankVal(r)
  rankMap = containers.Map({'2','3','4','5','6','7','8','9','T','J','Q','K','A'}, 2:14);
  val = rankMap(r);
endfunction


function [category, value] = evaluateHandComplete(cards)
  % Returns [category, tiebreaker_value]
  % category: 1=high card, 2=pair, 3=two pair, 4=trips, 5=straight,
  %           6=flush, 7=full house, 8=quads, 9=straight flush
  % value: numeric tiebreaker for comparing hands in same category

  if length(cards) < 5
    category = 0;
    value = 0;
    return;
  endif

  % Extract ranks and suits
  ranks = zeros(1, length(cards));
  suits = {};
  for i = 1:length(cards)
    ranks(i) = rankVal(cards{i}(1));
    suits{i} = cards{i}(2);
  endfor

  % Count rank frequencies
  rankCounts = zeros(1, 15);
  for r = ranks
    rankCounts(r)++;
  endfor

  % Find quads, trips, pairs
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

  flushSuit = '';
  for s = {'s','h','d','c'}
    if isKey(suitCounts, s{1}) && suitCounts(s{1}) >= 5
      flushSuit = s{1};
      break;
    endif
  endfor

  isFlush = ~isempty(flushSuit);

  % Check straight
  uniqueRanks = unique(ranks);
  isStraight = false;
  straightHigh = 0;

  % Check regular straights
  for i = 1:(length(uniqueRanks)-4)
    window = uniqueRanks(i:i+4);
    if length(window) == 5 && max(window) - min(window) == 4
      isStraight = true;
      straightHigh = max(window);
    endif
  endfor

  % Check wheel (A-2-3-4-5)
  if any(ranks == 14) && any(ranks == 2) && any(ranks == 3) && any(ranks == 4) && any(ranks == 5)
    isStraight = true;
    if straightHigh == 0
      straightHigh = 5;  % Wheel straight high card is 5
    endif
  endif

  % Determine hand category and value
  if isStraight && isFlush
    category = 9;
    value = straightHigh * 1e10;
  elseif ~isempty(quads)
    category = 8;
    value = max(quads) * 1e10 + max(ranks);  % quads rank + kicker
  elseif ~isempty(trips) && ~isempty(pairs)
    category = 7;
    value = max(trips) * 1e10 + max(pairs);  % trips rank + pair rank
  elseif isFlush
    category = 6;
    flushRanks = sort(ranks(strcmp(suits, flushSuit)), 'descend');
    value = flushRanks(1)*1e10 + flushRanks(2)*1e8 + flushRanks(3)*1e6 + flushRanks(4)*1e4 + flushRanks(5)*1e2;
  elseif isStraight
    category = 5;
    value = straightHigh * 1e10;
  elseif ~isempty(trips)
    category = 4;
    kickers = sort(ranks(ranks ~= max(trips)), 'descend');
    value = max(trips) * 1e10 + kickers(1) * 1e6 + kickers(2) * 1e4;
  elseif length(pairs) >= 2
    category = 3;
    sortedPairs = sort(pairs, 'descend');
    kicker = max(ranks(ranks ~= sortedPairs(1) & ranks ~= sortedPairs(2)));
    value = sortedPairs(1) * 1e10 + sortedPairs(2) * 1e8 + kicker * 1e6;
  elseif length(pairs) == 1
    category = 2;
    kickers = sort(ranks(ranks ~= pairs(1)), 'descend');
    value = pairs(1) * 1e10 + kickers(1) * 1e8 + kickers(2) * 1e6 + kickers(3) * 1e4;
  else
    category = 1;
    sortedRanks = sort(ranks, 'descend');
    value = sortedRanks(1)*1e10 + sortedRanks(2)*1e8 + sortedRanks(3)*1e6 + sortedRanks(4)*1e4 + sortedRanks(5)*1e2;
  endif
endfunction


function name = handName(category)
  names = {"High Card", "One Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush"};
  if category >= 1 && category <= 9
    name = names{category};
  else
    name = "Unknown";
  endif
endfunction


% ------------------------------------------------------------
% RANGE DEFINITIONS
% ------------------------------------------------------------

function range = getPreflopRange(action, position)
  % Returns cell array of hand strings like {"AKs", "AKo", "QQ", ...}
  % action: "open", "3bet", "call_3bet", "4bet"
  % position: "EP", "MP", "CO", "BTN", "SB", "BB"

  if strcmp(action, "open") && strcmp(position, "CO")
    % CO opening range (~25%)
    range = {"AA","KK","QQ","JJ","TT","99","88","77","66","55","44","33","22",...
             "AKs","AKo","AQs","AQo","AJs","AJo","ATs","ATo","A9s","A8s","A7s","A6s","A5s","A4s","A3s","A2s",...
             "KQs","KQo","KJs","KJo","KTs","KTo","K9s",...
             "QJs","QJo","QTs","QTo","Q9s",...
             "JTs","JTo","J9s","T9s","T8s","98s","87s","76s","65s"};
  elseif strcmp(action, "3bet") && strcmp(position, "BB")
    % BB 3-betting vs CO (~12%)
    range = {"AA","KK","QQ","JJ","TT","99",...
             "AKs","AKo","AQs","AQo","AJs","ATs","A5s","A4s",...
             "KQs","KJs","QJs","JTs","T9s","98s"};
  elseif strcmp(action, "call_3bet")
    % Calling 3-bet range
    range = {"JJ","TT","99","88","77",...
             "AQs","AQo","AJs","AJo","ATs",...
             "KQs","KJs","QJs","JTs","T9s","98s","87s","76s"};
  else
    % Default wide range
    range = {"AA","KK","QQ","JJ","TT","99","88","77","66","55",...
             "AKs","AKo","AQs","AQo","AJs","AJo","ATs",...
             "KQs","KJs","QJs","JTs"};
  endif
endfunction


function hands = expandRange(rangeStrings, deck)
  % Convert range strings like "AKs" into actual card combos like {"Ks As"}
  hands = {};

  for i = 1:length(rangeStrings)
    handStr = rangeStrings{i};

    if length(handStr) == 2  % Pair like "AA"
      rank = handStr(1);
      % Generate all 6 combos of this pair
      suits = {'s','h','d','c'};
      for s1 = 1:4
        for s2 = (s1+1):4
          hands{end+1} = {[rank suits{s1}], [rank suits{s2}]};
        endfor
      endfor

    elseif length(handStr) == 3
      rank1 = handStr(1);
      rank2 = handStr(2);
      suitedness = handStr(3);

      suits = {'s','h','d','c'};

      if suitedness == 's'  % Suited - 4 combos
        for s = 1:4
          hands{end+1} = {[rank1 suits{s}], [rank2 suits{s}]};
        endfor
      else  % Offsuit - 12 combos
        for s1 = 1:4
          for s2 = 1:4
            if s1 ~= s2
              hands{end+1} = {[rank1 suits{s1}], [rank2 suits{s2}]};
            endif
          endfor
        endfor
      endif
    endif
  endfor
endfunction


% ------------------------------------------------------------
% MONTE CARLO EQUITY CALCULATOR
% ------------------------------------------------------------

function equity = calculateEquity(heroHand, board, villainRange, deck, numSims)
  % heroHand: {card1, card2}
  % board: {card1, card2, ...} (can be 0-5 cards)
  % villainRange: cell array of possible villain hands {{c1,c2}, {c1,c2}, ...}
  % Returns equity as 0.0 to 1.0

  if isempty(villainRange)
    equity = 0.5;
    return;
  endif

  wins = 0;
  ties = 0;
  totalSims = 0;

  % Remove known cards from deck
  usedCards = [heroHand, board];
  availableDeck = {};
  for i = 1:length(deck)
    isUsed = false;
    for j = 1:length(usedCards)
      if strcmp(deck{i}, usedCards{j})
        isUsed = true;
        break;
      endif
    endfor
    if ~isUsed
      availableDeck{end+1} = deck{i};
    endif
  endfor

  for sim = 1:numSims
    % Pick random villain hand from range
    validVillainHands = {};
    for v = 1:length(villainRange)
      vHand = villainRange{v};
      % Check if villain hand conflicts with known cards
      conflicts = false;
      for c = usedCards
        if strcmp(vHand{1}, c{1}) || strcmp(vHand{2}, c{1})
          conflicts = true;
          break;
        endif
      endfor
      if ~conflicts
        validVillainHands{end+1} = vHand;
      endif
    endfor

    if isempty(validVillainHands)
      continue;
    endif

    villainHand = validVillainHands{randi(length(validVillainHands))};

    % Remove villain cards from available deck
    simDeck = {};
    for i = 1:length(availableDeck)
      if ~strcmp(availableDeck{i}, villainHand{1}) && ~strcmp(availableDeck{i}, villainHand{2})
        simDeck{end+1} = availableDeck{i};
      endif
    endfor

    % Complete the board if needed
    cardsNeeded = 5 - length(board);
    simBoard = board;

    if cardsNeeded > 0 && length(simDeck) >= cardsNeeded
      shuffled = simDeck(randperm(length(simDeck)));
      for c = 1:cardsNeeded
        simBoard{end+1} = shuffled{c};
      endfor
    endif

    if length(simBoard) < 5
      continue;
    endif

    % Evaluate both hands
    [heroCat, heroVal] = evaluateHandComplete([heroHand, simBoard]);
    [villainCat, villainVal] = evaluateHandComplete([villainHand, simBoard]);

    totalSims++;

    if heroCat > villainCat || (heroCat == villainCat && heroVal > villainVal)
      wins++;
    elseif heroCat == villainCat && heroVal == villainVal
      ties++;
    endif
  endfor

  if totalSims == 0
    equity = 0.5;
  else
    equity = (wins + ties * 0.5) / totalSims;
  endif
endfunction


% ------------------------------------------------------------
% GTO MATH FUNCTIONS
% ------------------------------------------------------------

function potOdds = calcPotOdds(potFacingYou, bet)
  % Pot odds = bet / (potFacingYou + bet)
  % potFacingYou should be the pot AFTER villain's bet, before you act
  % This gives you the minimum equity needed to call
  potOdds = bet / (potFacingYou + bet);
endfunction


function ev = calcCallEV(equity, potFacingYou, betAmount)
  % When you call:
  % - Pot you're facing: potFacingYou (includes villain's bet)
  % - You must invest: betAmount
  % - Win outcome: gain potFacingYou (you win the pot facing you)
  % - Lose outcome: lose betAmount
  % EV = equity * potFacingYou - (1-equity) * betAmount
  ev = equity * potFacingYou - (1 - equity) * betAmount;
endfunction


function mdf = calcMDF(betSize, pot)
  % Minimum Defense Frequency = 1 - (bet / (pot + bet))
  mdf = 1 - (betSize / (pot + betSize));
endfunction


function ratio = calcOptimalBluffRatio(betSize, pot)
  % Optimal bluff:value ratio = betSize / pot
  ratio = betSize / pot;
endfunction


function spr = calcSPR(effectiveStack, pot)
  % Stack to Pot Ratio
  spr = effectiveStack / pot;
endfunction


% ------------------------------------------------------------
% GTO DECISION ANALYZER
% ------------------------------------------------------------

function [optimalAction, analysis] = analyzeGTODecision(heroHand, board, equity, potBeforeBet, betAmount, effectiveStack, street, mode)
  % Returns optimal action and detailed analysis
  % mode: "beginner", "intermediate", "advanced"

  analysis = struct();

  % Calculate all relevant metrics
  % potBeforeBet is pot BEFORE villain's bet, so add betAmount for pot facing you
  potFacingYou = potBeforeBet + betAmount;
  potOdds = calcPotOdds(potFacingYou, betAmount);
  evFold = 0;
  evCall = calcCallEV(equity, potFacingYou, betAmount);
  mdf = calcMDF(betAmount, potFacingYou);
  spr = calcSPR(effectiveStack, potBeforeBet);

  analysis.equity = equity;
  analysis.potOdds = potOdds;
  analysis.evFold = evFold;
  analysis.evCall = evCall;
  analysis.mdf = mdf;
  analysis.spr = spr;

  % Basic GTO decision
  if equity >= potOdds
    if evCall > 0
      optimalAction = "call";
      analysis.reason = sprintf("Equity %.1f%% > pot odds %.1f%%, EV(call)=$%.2f", equity*100, potOdds*100, evCall);
    else
      optimalAction = "fold";
      analysis.reason = sprintf("EV(call)=$%.2f is negative", evCall);
    endif
  else
    optimalAction = "fold";
    analysis.reason = sprintf("Equity %.1f%% < pot odds %.1f%%, EV(call)=$%.2f", equity*100, potOdds*100, evCall);
  endif

  % Check if raise might be better (simplified)
  [heroCat, heroVal] = evaluateHandComplete([heroHand, board]);

  % Consider raising with strong hands or strong draws
  if equity > 0.6 && spr < 10
    analysis.raiseConsideration = "Strong hand + low SPR → raising for value is good";
  elseif equity > 0.35 && equity < 0.55 && strcmp(street, "flop")
    analysis.raiseConsideration = "Semi-bluff raise possible with draw + fold equity";
  else
    analysis.raiseConsideration = "Raising not optimal here";
  endif
endfunction


% ------------------------------------------------------------
% TEACHING DISPLAY
% ------------------------------------------------------------

function teachDecisionGTO(playerAction, optimalAction, analysis, street, mode)
  printf("\n");

  if strcmp(mode, "beginner")
    printf("╔════════════════════════════════════════╗\n");
    printf("║      BEGINNER ANALYSIS (%s)         ║\n", upper(street));
    printf("╚════════════════════════════════════════╝\n\n");

    printf("Your action: %s\n", upper(playerAction));
    printf("Best action: %s\n\n", upper(optimalAction));

    printf("Your equity:     %.1f%%\n", analysis.equity * 100);
    printf("Pot odds needed: %.1f%%\n\n", analysis.potOdds * 100);

    if analysis.equity >= analysis.potOdds
      printf("✓ You have enough equity to call!\n");
    else
      printf("✗ Not enough equity - should fold\n");
    endif

  else
    printf("╔════════════════════════════════════════╗\n");
    printf("║         GTO ANALYSIS (%s)           ║\n", upper(street));
    printf("╚════════════════════════════════════════╝\n\n");

    printf("Your action: %s\n", upper(playerAction));
    printf("GTO action:  %s\n\n", upper(optimalAction));

    printf("─── Mathematics ───\n");
    printf("Your equity:       %.1f%%\n", analysis.equity * 100);
    printf("Pot odds needed:   %.1f%%\n", analysis.potOdds * 100);
    printf("EV(fold):          $%.2f\n", analysis.evFold);
    printf("EV(call):          $%.2f\n", analysis.evCall);

    if strcmp(mode, "advanced")
      printf("MDF (min defense): %.1f%%\n", analysis.mdf * 100);
      printf("SPR:               %.1f\n", analysis.spr);
    endif

    printf("\n─── Reasoning ───\n");
    printf("%s\n", analysis.reason);

    if strcmp(mode, "advanced") && isfield(analysis, 'raiseConsideration')
      printf("\nRaise consideration: %s\n", analysis.raiseConsideration);
    endif
  endif

  if strcmp(playerAction, optimalAction)
    printf("\n✓ CORRECT! Optimal play.\n");
  else
    evLost = abs(analysis.evCall - analysis.evFold);
    printf("\n✗ SUBOPTIMAL: EV loss = $%.2f\n", evLost);
  endif

  printf("\nPress ENTER to continue...");
  input("");
endfunction


% ------------------------------------------------------------
% PLAYER INPUT
% ------------------------------------------------------------

function [action, amount] = getPlayerAction(pot, toCall, stack, canCheck)
  printf("\n");
  printf("Pot: $%d | Stack: $%d", pot, stack);
  if ~canCheck
    printf(" | To call: $%d", toCall);
  endif
  printf("\n");

  if canCheck
    printf("Options: [c]heck, [b]et, [f]old\n");
  else
    printf("Options: [f]old, [c]all $%d, [r]aise\n", toCall);
  endif

  printf("Your decision: ");
  decision = input("", "s");

  if isempty(decision)
    decision = "c";
  endif

  if decision(1) == 'f' || decision(1) == 'F'
    action = "fold";
    amount = 0;
  elseif decision(1) == 'c' || decision(1) == 'C'
    if canCheck
      action = "check";
      amount = 0;
    else
      action = "call";
      amount = toCall;
    endif
  elseif (decision(1) == 'b' || decision(1) == 'B') && canCheck
    printf("Bet amount: $");
    amount = input("");
    amount = min(amount, stack);
    action = "bet";
  elseif decision(1) == 'r' || decision(1) == 'R'
    printf("Raise to: $");
    amount = input("");
    amount = min(amount, stack);
    action = "raise";
  else
    printf("Invalid input.\n");
    [action, amount] = getPlayerAction(pot, toCall, stack, canCheck);
  endif
endfunction


% ------------------------------------------------------------
% GAME ENGINE
% ------------------------------------------------------------

function runTraining(mode, settings)

  stack = settings.stack;
  villain_stack = settings.stack;
  bb = 20;

  printf("\n");
  printf("════════════════════════════════════════\n");
  printf("  Starting %s training\n", upper(mode));
  printf("  Stack: $%d | Big Blind: $%d\n", stack, bb);
  printf("════════════════════════════════════════\n");

  handsPlayed = 0;

  while stack > bb && villain_stack > bb

    printf("\n\n");
    printf("════════════════════════════════════════\n");
    printf("      HAND #%d (Stack: $%d)\n", handsPlayed + 1, stack);
    printf("════════════════════════════════════════\n");

    % Shuffle and deal
    ranks = {"2","3","4","5","6","7","8","9","T","J","Q","K","A"};
    suits = {"s","h","d","c"};
    deck = {};
    for r = 1:length(ranks)
      for s = 1:length(suits)
        deck{end+1} = [ranks{r} suits{s}];
      endfor
    endfor

    deckShuffled = shuffleDeck(deck);

    heroHand = {deckShuffled{1}, deckShuffled{2}};
    villainHand = {deckShuffled{3}, deckShuffled{4}};

    % Post blinds (you are BB, villain is SB/BTN)
    pot = 30;  % 10 SB + 20 BB
    stack -= 20;
    villain_stack -= 10;

    printf("\nYour hand: ");
    displayHand(heroHand);
    printf("\n");

    [heroCat, heroVal] = evaluateHandComplete(heroHand);
    printf("Hand: %s\n", handName(heroCat));

    % PREFLOP - Villain opens
    printf("\n─── PREFLOP ───\n");
    printf("Villain raises to $60\n");

    toCall = 40;  % 60 - 20 already posted
    pot += 60;

    villainPreflopRange = getPreflopRange("open", "CO");
    villainRangeHands = expandRange(villainPreflopRange, deck);

    % Calculate preflop equity vs range
    if strcmp(mode, "quick") || strcmp(mode, "beginner")
      % Use simplified equity for speed in beginner/quick modes
      [heroCat, heroVal] = evaluateHandComplete(heroHand);
      if heroCat >= 2  % Pair or better
        preflopEquity = 0.55;
      else
        % Rough estimate based on high card
        heroRanks = [rankVal(heroHand{1}(1)), rankVal(heroHand{2}(1))];
        avgRank = mean(heroRanks);
        if avgRank >= 12  % AK, AQ, KQ type hands
          preflopEquity = 0.50;
        elseif avgRank >= 9  % Medium hands
          preflopEquity = 0.40;
        else  % Weak hands
          preflopEquity = 0.30;
        endif
      endif
      printf("Your estimated equity: %.1f%%\n", preflopEquity * 100);
    else
      printf("Calculating equity vs villain range (this may take a few seconds)...\n");
      preflopEquity = calculateEquity(heroHand, {}, villainRangeHands, deck, settings.numSims);
      printf("Your equity vs villain's range: %.1f%%\n", preflopEquity * 100);
    endif

    [action, amount] = getPlayerAction(pot, toCall, stack, false);

    if strcmp(action, "fold")
      printf("\nYou folded preflop.\n");
      handsPlayed++;
      continue;
    endif

    stack -= toCall;
    pot += toCall;

    % FLOP
    board = {deckShuffled{5}, deckShuffled{6}, deckShuffled{7}};

    printf("\n\n─── FLOP ───\n");
    printf("Board: ");
    displayHand(board);
    printf("\n");

    [flopCat, flopVal] = evaluateHandComplete([heroHand, board]);
    printf("Your hand: %s\n", handName(flopCat));

    % Villain bets 70% pot
    betAmount = round(pot * 0.7);
    if betAmount > villain_stack
      betAmount = villain_stack;
    endif

    printf("Villain bets $%d\n", betAmount);

    potBeforeBet = pot;
    villain_stack -= betAmount;
    pot += betAmount;

    % Calculate real equity vs villain's range on this flop
    if strcmp(mode, "quick") || strcmp(mode, "beginner")
      % Simplified equity based on hand strength
      flopEquity = 0.3 + (flopCat - 1) * 0.08;  % 30% for high card, up to 94% for straight flush
      flopEquity = max(0.15, min(0.95, flopEquity));
    else
      printf("Calculating equity (please wait)...\n");
      flopEquity = calculateEquity(heroHand, board, villainRangeHands, deck, settings.numSims);
    endif

    [optimalAction, analysis] = analyzeGTODecision(heroHand, board, flopEquity, potBeforeBet, betAmount, stack, "flop", mode);

    [action, amount] = getPlayerAction(pot, betAmount, stack, false);

    teachDecisionGTO(action, optimalAction, analysis, "flop", mode);

    if strcmp(action, "fold")
      printf("\nYou folded on flop.\n");
      handsPlayed++;
      continue;
    endif

    stack -= betAmount;
    pot += betAmount;

    % TURN
    board{end+1} = deckShuffled{8};

    printf("\n\n─── TURN ───\n");
    printf("Board: ");
    displayHand(board);
    printf("\n");

    [turnCat, turnVal] = evaluateHandComplete([heroHand, board]);
    printf("Your hand: %s\n", handName(turnCat));

    % Villain bets 70% pot again
    betAmount = round(pot * 0.7);
    if betAmount > villain_stack
      betAmount = villain_stack;
    endif

    printf("Villain bets $%d\n", betAmount);

    potBeforeBet = pot;
    villain_stack -= betAmount;
    pot += betAmount;

    % Calculate turn equity
    if strcmp(mode, "quick") || strcmp(mode, "beginner")
      % Simplified equity based on hand strength
      turnEquity = 0.3 + (turnCat - 1) * 0.08;
      turnEquity = max(0.15, min(0.95, turnEquity));
    else
      printf("Calculating equity (please wait)...\n");
      turnEquity = calculateEquity(heroHand, board, villainRangeHands, deck, settings.numSims);
    endif

    [optimalAction, analysis] = analyzeGTODecision(heroHand, board, turnEquity, potBeforeBet, betAmount, stack, "turn", mode);

    [action, amount] = getPlayerAction(pot, betAmount, stack, false);

    teachDecisionGTO(action, optimalAction, analysis, "turn", mode);

    if strcmp(action, "fold")
      printf("\nYou folded on turn.\n");
      handsPlayed++;
      continue;
    endif

    stack -= betAmount;
    pot += betAmount;

    % RIVER
    board{end+1} = deckShuffled{9};

    printf("\n\n─── RIVER ───\n");
    printf("Board: ");
    displayHand(board);
    printf("\n");

    [riverCat, riverVal] = evaluateHandComplete([heroHand, board]);
    printf("Your hand: %s\n", handName(riverCat));

    % SHOWDOWN
    [villainCat, villainVal] = evaluateHandComplete([villainHand, board]);

    printf("\n─── SHOWDOWN ───\n");
    printf("Villain: ");
    displayHand(villainHand);
    printf(" (%s)\n", handName(villainCat));
    printf("You:     ");
    displayHand(heroHand);
    printf(" (%s)\n", handName(riverCat));

    if riverCat > villainCat || (riverCat == villainCat && riverVal > villainVal)
      printf("\n*** YOU WIN $%d! ***\n", pot);
      stack += pot;
    elseif villainCat > riverCat || (villainCat == riverCat && villainVal > riverVal)
      printf("\nVillain wins $%d\n", pot);
      villain_stack += pot;
    else
      printf("\nChop pot - $%d each\n", pot/2);
      stack += pot/2;
      villain_stack += pot/2;
    endif

    handsPlayed++;
    printf("\nYour stack: $%d | Hands played: %d\n", stack, handsPlayed);
    printf("\nContinue? [Enter]=yes, Q=quit: ");
    user_input = input("", "s");
    if ~isempty(user_input) && (user_input(1) == 'Q' || user_input(1) == 'q')
      break;
    endif

  endwhile

  printf("\n\n");
  printf("═══════════════════════════════════════\n");
  printf("       SESSION COMPLETE\n");
  printf("═══════════════════════════════════════\n");
  printf("Hands played: %d\n", handsPlayed);
  printf("Final stack:  $%d\n", stack);
  printf("P/L:          $%d\n", stack - settings.stack);
  printf("\nThank you for training!\n");
endfunction


% ------------------------------------------------------------
% MAIN PROGRAM
% ------------------------------------------------------------

% Default settings
settings = struct();
settings.numSims = 500;  % Reduced default for better performance
settings.stack = 1000;

while true
  choice = showMenu();

  if choice(1) == 'q' || choice(1) == 'Q'
    printf("\nGoodbye! Keep studying GTO!\n\n");
    break;
  elseif choice(1) == '1'
    runTraining("beginner", settings);
  elseif choice(1) == '2'
    runTraining("intermediate", settings);
  elseif choice(1) == '3'
    runTraining("advanced", settings);
  elseif choice(1) == '4'
    runTraining("quick", settings);
  elseif choice(1) == '5'
    settings = showSettings();
  else
    printf("\nInvalid choice. Please try again.\n");
  endif
endwhile
