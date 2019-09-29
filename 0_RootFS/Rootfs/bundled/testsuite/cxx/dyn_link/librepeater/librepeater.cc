#include <string>
#include <math.h>

std::string repeater(std::string a, double amnt) {
    int reps = (int)round(sqrt(amnt));
    std::string ret = std::string("");
    for (int i=0; i<reps; ++i) {
        ret += a;
    }
    return ret;
}
