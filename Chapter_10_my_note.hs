module Chapter_10_my_note where

import           Test.QuickCheck
import           Test.QuickCheck.Function

doubleAllv1 :: [Integer] -> [Integer]
doubleAllv1 ls    = [x * 2 | x <- ls]

doubleAllv2 :: [Integer] -> [Integer]
doubleAllv2 []          = []
doubleAllv2 (x : xs)    = (2 * x) : doubleAllv2 xs

doubleAllv3 :: [Integer] -> [Integer]
doubleAllv3    = map (\x -> 2 * x)

lengthMapSum :: [a] -> Int
lengthMapSum    = sum . map (\x -> 1)

addUpv1 :: [Integer] -> [Integer]
addUpv1 ns    = filter (> 1) (map (+ 1) ns)

addUpv2 :: [Integer] -> [Integer]
addUpv2 ns    = map (+ 1) (filter (> 0) ns)

squareList :: [Integer] -> [Integer]
squareList    = map (\x -> x * x)

squareListSum :: [Integer] -> Integer
squareListSum    = sum . map (\x -> x * x)

allGreaterZero :: [Integer] -> Bool
allGreaterZero    = and . map (> 0)

minFunScope :: (Ord t, Num t) => (t -> t) -> [t] -> t
minFunScope func ls    = minimum (map func ls)

allFunEqual :: (Ord t, Num t) => (t -> t) -> [t] -> Bool
allFunEqual func ls    = null (filter (/= func (head ls)) (map func ls))

allGreaterFunZero :: (Ord t, Num t) => (t -> t) -> [t] -> Bool
allGreaterFunZero func ls    = and (map ((> 0) . func) ls)

funIssorted :: (Ord t, Num t) => (t -> t) -> [t] -> Bool
funIssorted func ls    = isSorted (map func ls)

isSorted :: (Ord t, Num t) => [t] -> Bool
isSorted []              = True
isSorted [_]             = True
isSorted (x : y : xs)    = x < y && isSorted (y : xs)

twice :: (t -> t) -> t -> t
twice func    = func . func

iter :: Integer -> (t -> t) -> t -> t
iter times func val
    | times < 0     = error "wrong time data given"
    | times == 0    = val
    | otherwise     = iter (times - 1) func (func val)

base2 :: Integer -> Integer
base2 n
    | n >= 0       = iter n (\x -> 2 * x) 1
    | otherwise    = error "time negative"

propFilter :: Fun Integer Bool -> [Integer] -> Bool
propFilter func ls    = filter (apply func) ls == filter (apply func) (filter (apply func) ls)
