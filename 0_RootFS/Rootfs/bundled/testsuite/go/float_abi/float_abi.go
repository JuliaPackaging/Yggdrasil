package main

import "fmt"
import "math/rand"

func average(xs []float64) float64 {
    total := 0.0
    for _, v := range xs {
        total += v
    }
    return total / float64(len(xs))
}

func main() {
    rand.Seed(0x6a756c6961)
    xs := make([]float64, 1000)
    for n := 0; n < 1000; n++ {
        xs[n] = rand.Float64()
    }
    fmt.Println("average: ", average(xs))
}
