module Chapter_12_my_note where

import           Test.QuickCheck
import           Chapter_8_my_note (randInt)
import           Prelude hiding ((<*>), Word)
import           Data.Map (Map, fromList, (!))
import           System.Console.ANSI
import           Chapter_11_my_note ((>.>))
import           Chapter_10_my_note (dropUntil, getUntil)
import           Data.Char (toLower)

type Picture = [String]

_flipH :: Picture -> Picture
_flipH    = reverse

_flipV :: Picture -> Picture
_flipV    = map reverse

_above :: Picture -> Picture -> Picture
_above    = (++)

_beside :: Picture -> Picture -> Picture
_beside    = zipWith (++)

_invertColor :: Picture -> Picture
_invertColor    = map (map (\ch -> if ch == '.' then '#' else '.'))

_superImpose :: Picture -> Picture -> Picture
_superImpose    = zipWith (zipWith (\c1 c2 -> if c1 == c2 then c1 else '#'))

_printPicture :: Picture -> IO ()
_printPicture    = putStr . concat . map (++ "\n")

_chessBoard :: Int -> Picture
_chessBoard size    = zipWith ($)
    ((fst . splitAt size . concat . replicate size) [fst, reverse . snd])
    ((replicate size . splitAt size . concat . replicate size) "#.")

type Bicture = [[Bool]]

_binvertColor :: Bicture -> Bicture
_binvertColor    = map (map not)

_bsuperImpose :: Bicture -> Bicture -> Bicture
_bsuperImpose    = zipWith (zipWith (\b1 b2 -> (b1 == b2) && b2))

_bprintPicture :: Bicture -> IO ()
_bprintPicture    = putStr . concat . map ((++ "\n") . map (\_b -> if _b
                                                                   then '#'
                                                                   else '.'))

createPic :: Int -> Int -> Picture
createPic h w    = replicate h ((concat . replicate w) ".")

addPt :: (Int, Int) -> Picture -> Picture
addPt (h, w) pic    = take h pic ++ [take w (pic !! h) ++ "#" ++ drop (w + 1) (pic !! h)]
                      ++ drop (h + 1) pic

addPts :: [(Int, Int)] -> Picture -> Picture
addPts pts pic    = foldr addPt pic pts

qualify :: [(Int, Int)] -> (Int, Int) -> [(Int, Int)]
qualify ptl sz    = filter (\(y, x) -> (fst sz >= y) && (x >= 0)
                                       && (snd sz >= x) && (y >= 0)) ptl

makePicture :: Int -> Int -> [(Int, Int)] -> Picture
makePicture w h pts    = addPts (qualify pts (h, w)) (createPic h w)

picSize :: Picture -> (Int, Int)
picSize pic    = (length (head pic), length pic)

pointsCreate :: Int -> Int -> [(Int, Int)]
pointsCreate w h    = zip
    ((concat . (map (concat . replicate w))) (map (\x -> [x]) [0 .. (h - 1)]))
    ((concat . replicate h) [0 .. (w - 1)])

isBlack :: (Int, Int) -> Picture -> Bool
isBlack (h, w) pic    = (pic !! h) !! w == '#'

blackList :: Picture -> [(Int, Int)]
blackList pic    = filter (`isBlack` pic) (uncurry pointsCreate (picSize pic))

picToRep :: Picture -> (Int, Int, [(Int, Int)])
picToRep pic    = ((fst . picSize) pic, (snd . picSize) pic, blackList pic)

type Rep = (Int, Int, [(Int, Int)])

repRotate :: Rep -> Rep
repRotate (w, h, locs)    = (h, w, map (\(y, x) -> (x, h - 1 - y)) locs)

data Move = Rock | Paper | Scissors
            deriving (Show, Eq)

type Strategy = [Move] -> Move

beat :: Move -> Move
beat Rock  = Paper
beat Paper = Scissors
beat _     = Rock

lose :: Move -> Move
lose Rock  = Scissors
lose Paper = Rock
lose _     = Paper

alternate :: Strategy -> Strategy -> [Move] -> Move
alternate str1 str2 moves    = map ($ moves) [str1, str2] !! (length moves `mod` 2)

sToss :: Strategy -> Strategy -> Strategy
sToss str1 str2    = [str1, str2] !! (fromInteger (randInt 2) :: Int)

sTossList :: [Strategy] -> Strategy
sTossList []    = \moves -> head moves
sTossList ls    = ls !! (fromInteger (randInt ((toInteger . length) ls)) :: Int)

alternativeList :: [Strategy] -> [Move] -> Strategy
alternativeList strs moves    = strs !! (length moves `mod` length strs)

type Moves = [Move]

counterMoves :: Moves -> Strategy -> Moves
counterMoves mv str    = map (str . flip take mv) [1 .. length mv]

mvCompete :: Move -> Move -> Integer
mvCompete mv1 mv2
    | mv1 == mv2         = 0
    | beat mv1 == mv2    = 1
    | otherwise          = -1

outcome :: Strategy -> Moves -> Integer
outcome str mvs    = sum (zipWith mvCompete (counterMoves mvs str) mvs)

outcomes :: [Strategy] -> Moves -> [Integer]
outcomes strs mvs    = map (`outcome` mvs) strs

maxWins :: [Strategy] -> Moves -> [Strategy]
maxWins strs moves    = filter (\x -> outcome x moves == maximum (outcomes strs moves)) strs

train :: Moves -> [Strategy] -> Strategy
train moves strs    = bestStrategy !! (fromInteger
                                        (randInt ((toInteger . length) strs)) :: Int)
  where bestStrategy :: [Strategy]
        bestStrategy    = maxWins strs moves

type RegExp = String -> Bool

epsilon :: RegExp
epsilon    = (== "")

char :: Char -> RegExp
char ch    = (== [ch])

(|||) :: RegExp -> RegExp -> RegExp
e1 ||| e2    = \x -> e1 x || e2 x

(&&&) :: RegExp -> RegExp -> RegExp
e1 &&& e2    = \x -> e1 x && e2 x

rnot :: RegExp -> RegExp
rnot e    = not . e

splits :: String -> [(String, String)]
splits str    = map (`splitAt` str) [1 .. length str]

(<*>) :: RegExp -> RegExp -> RegExp
e1 <*> e2    = \x -> or [e1 y && e2 z | (y, z) <- splits x]

star :: RegExp -> RegExp
star p    = epsilon ||| (p <*> star p)

a, b :: RegExp
a    = char 'a'
b    = char 'b'

test1 :: RegExp
test1    = star ((a ||| b) <*> (a ||| b))

test2 :: RegExp
test2    = star test1

prop_test12 :: String -> Bool
prop_test12 str    = test1 str == test2 str

subseqs :: String -> [String]
subseqs str    = map fst (concat (map (splits . snd . (`splitAt` str)) [0 .. length str]))

partlyMatch :: RegExp -> (Int -> Bool) -> RegExp
partlyMatch e i    = i . length . filter e . subseqs

plus, option :: RegExp -> RegExp
option e    = partlyMatch e (== 0) ||| partlyMatch e (== 1)
plus e      = partlyMatch e (>= 2)

latinMatch :: RegExp
latinMatch    = foldr1 (|||) (map char (['a' .. 'z'] ++ ['A' .. 'Z']))

digitMatch :: RegExp
digitMatch    = foldr1 (|||) (map char ['0' .. '9'])

zeroHeadProp :: RegExp
zeroHeadProp    = ((>= 2) . length) &&& rnot ((char '0' . (\x -> [x]) . head)
                                               &&& (digitMatch . (\x -> [x]) . (!! 1)))

headDigit :: RegExp
headDigit    = digitMatch . (\x -> [x]) . head

zeroTailProp :: RegExp
zeroTailProp    = not . char '0' . init

derivMatch :: RegExp
derivMatch    = partlyMatch (char '.') (== 1) &&& partlyMatch latinMatch (== 0)
                &&& headDigit &&& zeroHeadProp &&& zeroTailProp

abComposeMost2a :: RegExp
abComposeMost2a    = partlyMatch (char 'a') (<= 2) &&& star (a ||| b)

abComposeWith2a :: RegExp
abComposeWith2a    = partlyMatch (char 'a') (== 2) &&& star (a ||| b)

length3withab :: RegExp
length3withab    = (a ||| b) <*> (a ||| b) <*> (a ||| b)

composeabnoaabb :: RegExp
composeabnoaabb    = star (a ||| b) &&& partlyMatch (a <*> a) (== 0)
                     &&& partlyMatch (b <*> b) (== 0)

type Natural a = (a -> a) -> (a -> a)

zero :: Natural a
zero _    = id

one :: Natural a
one f    = f

two :: Natural a
two f    = f . f

int :: Natural Int -> Int
int n    = n (+1) 0

nsucc :: Natural a -> Natural a
nsucc now f    = f . now f

nplus :: Natural a -> Natural a -> Natural a
nplus n m f    = n f . m f

ntimes :: Natural a -> Natural a -> Natural a
ntimes n m    = n . m

type Position = (Int, Int)

type Bitmap = Position -> Pixel

type Pixel = Char

data Location = FloatExp Int Int
              | LocalExp Int Int Int Int
                deriving (Eq, Show)

bitToPic :: Bitmap -> Location -> Picture
bitToPic bitms (FloatExp widt high)      = map (bitToLine bitms widt) [0 .. high - 1]
bitToPic bitms (LocalExp lx ly rx ry)    = map (bitToLine bitms (rx - lx)) [0 .. ry - ly - 1]

bitToLine :: Bitmap -> Int -> Int -> String
bitToLine bitms width height    = concatMap (\x -> [bitms (x, height)]) [0 .. width - 1]

picToBit :: Picture -> Bitmap
picToBit pic (x, y)    = if x < (length . head) pic && y < length pic
                         then (pic !! y) !! x
                         else error "out of scope."

mapPicTo :: Picture -> Map (Int, Int) Pixel
mapPicTo pic    = fromList (zip (createDots pic) (picToChars pic (createDots pic)))

mapPicToBit :: Picture -> Bitmap
mapPicToBit pic val    = mapPicTo pic ! val

createDots :: Picture -> [(Int, Int)]
createDots pic    = concatMap (\x -> (map (\y -> (x, y)) [0 .. width - 1])) [0 .. height - 1]
  where
    height, width :: Int
    height    = length pic
    width     = (length . head) pic

picToChars :: Picture -> [(Int, Int)] -> String
picToChars pic    = map (\(h, w) -> (pic !! h) !! w)

mapBitToPic :: Map Position Pixel -> Location -> Picture
mapBitToPic mapbase (FloatExp widt high)      = map (mapToLine mapbase widt) [0 .. high - 1]
mapBitToPic mapbase (LocalExp lx ly rx ry)    =
    map (mapToLine mapbase (rx - lx)) [0 .. ry - ly - 1]

mapToLine :: Map Position Pixel -> Int -> Int -> String
mapToLine mapbase width height    = concatMap (\x -> [mapbase ! (height, x)]) [0 .. width - 1]

-- fuck, change all Bitmap to picture, change picture, then change back to bitmap.
-- fuck, do not write.

demo :: IO ()
demo = do
    setCursorPosition 5 0
    setTitle "ANSI Terminal Short Example"

    setSGR [ SetConsoleIntensity BoldIntensity
           , SetColor Foreground Vivid Red
           ]
    putStr "Hello"

    setSGR [ SetConsoleIntensity NormalIntensity
           , SetColor Foreground Vivid White
           , SetColor Background Dull Blue
           ]
    putStrLn "World!"

type Doc = String
type Line = String
type Word = String

makeIndex :: Doc -> [([Int], Word)]
makeIndex    = shorten . amalgamate . makeLists . sortLs . allNumWords . numLines . _lines

shorten :: [([Int], Word)] -> [([Int], Word)]
shorten    = filter (\(_, y) -> length y > 3)

amalgamate :: [([Int], Word)] -> [([Int], Word)]
amalgamate []       = []
amalgamate [val]    = [val]
amalgamate ((n1, w1) : (n2, w2) : rest)
    | w1 == w2      = amalgamate ((n1 ++ n2, w1) : rest)
    | otherwise     = (n1, w1) : amalgamate ((n2, w2) : rest)

makeLists :: [(Int, Word)] -> [([Int], Word)]
makeLists    = map (\(x, y) -> ([x], y))

sortLs :: [(Int, Word)] -> [(Int, Word)]
sortLs []          = []
sortLs (p : ps)    = sortLs [q | q <- ps, orderPair q p] ++ [p]
                     ++ sortLs [q | q <- ps, not (orderPair q p)]

orderPair :: (Int, Word) -> (Int, Word) -> Bool
orderPair (n1, w1) (n2, w2)    = w1 `smallerThan` w2 || (w1 == w2 && n1 < n2)

smallerThan :: Word -> Word -> Bool
(w1 : wd1) `smallerThan` (w2 : wd2)    = if toLower w1 == toLower w2
                                         then wd1 `smallerThan` wd2
                                         else w1 < w2
_ `smallerThan` []                     = False
[] `smallerThan` (_ : _)               = True

allNumWords :: [(Int, Line)] -> [(Int, Word)]
allNumWords    = concatMap numWords

whiteSpace :: String
whiteSpace    = " \b\n\t;:.,\'\"!?()\\`"

isWhiteSpace :: Char -> Bool
isWhiteSpace    = flip elem whiteSpace

cleanHead :: Line -> Line
cleanHead    = dropUntil (not . isWhiteSpace)

_splitWds :: Line -> [Word]
_splitWds []    = []
_splitWds ln    = (cleanHead . getUntil isWhiteSpace . cleanHead) ln :
                  (_splitWds . cleanHead . dropUntil isWhiteSpace . cleanHead) ln

numWords :: (Int, Line) -> [(Int, Word)]
numWords (num, ln)    = zip (replicate ((length . _splitWds) ln) num) (_splitWds ln)

numLines :: [Line] -> [(Int, Line)]
numLines lns    = zip [1 .. length lns] lns

_lines :: Doc -> [Line]
_lines []       = []
_lines docum    = getUntil (== '\n') docum :
                  _lines ((dropUntil (/= '\n') . dropUntil (== '\n')) docum)

weakPrintIndex :: [([Int], Word)] -> IO ()
weakPrintIndex index    = putStrLn (concatMap ((++ "\n") . weakShowIndex) index)

weakShowIndex :: ([Int], Word) -> String
weakShowIndex (datas, word)    = word ++ concat (replicate (__width - length word) " ")
                                 ++ concatMap ((++ ", ") . show) (init datas)
                                 ++ (show . last) datas
  where __width    = 15 :: Int

mergeList :: [Int] -> [[Int]]
mergeList    = map (: [])

simplifyList :: [[Int]] -> [[Int]]
simplifyList []          = []
simplifyList [x]         = [x]
simplifyList (x : xs)    = if last x + 1 == (head . head) xs
                           then simplifyList ((x ++ head xs) : tail xs)
                           else x : simplifyList xs

strongList :: [Int] -> [[Int]]
strongList    = simplifyList . mergeList

strongExpress :: [Int] -> [String]
strongExpress ls    = map (\x -> if length x == 1
                                 then (show . head) x
                                 else (show . head) x ++ "-"
                                      ++ (show . last) x) (strongList ls)

strongShowIndex :: ([Int], Word) -> String
strongShowIndex (datas, word)    = word ++ concat (replicate (__width - length word) " ")
                                   ++ concatMap (++ ", ") ((init . strongExpress) datas)
                                   ++ (last . strongExpress) datas
  where __width    = 15 :: Int

strongPrintIndex :: [([Int], Word)] -> IO ()
strongPrintIndex index    = putStrLn (concatMap ((++ "\n") . strongShowIndex) index)
