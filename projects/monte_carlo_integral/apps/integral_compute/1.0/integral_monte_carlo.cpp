#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <unistd.h>

using namespace std;

// Function to integrate: f(x) = x^2 * sin(x) + 1
double f(double x) {
    return x * x * sin(x) + 1.0;
}

// Monte Carlo integration over [a, b]
double monte_carlo_integral(double a, double b, long long num_samples) {
    // Find max value of f in the interval for rejection sampling
    double max_f = 0.0;
    for (double x = a; x <= b; x += 0.01) {
        double val = f(x);
        if (val > max_f) max_f = val;
    }
    
    max_f *= 1.1; // Add 10% margin
    
    long long hits = 0;
    for (long long i = 0; i < num_samples; i++) {
        double x = a + (b - a) * ((double)rand() / RAND_MAX);
        double y = max_f * ((double)rand() / RAND_MAX);
        
        if (y <= f(x)) {
            hits++;
        }
    }
    
    double area = (b - a) * max_f * ((double)hits / num_samples);
    return area;
}

int main(int argc, char** argv) {
    if (argc < 5) {
        cerr << "Usage: " << argv[0] << " <a> <b> <num_samples> <output_file>" << endl;
        cerr << "Example: " << argv[0] << " 0 3.14159 10000000 result.txt" << endl;
        return 1;
    }
    
    double a = atof(argv[1]);
    double b = atof(argv[2]);
    long long num_samples = atoll(argv[3]);
    
    srand(time(NULL) + getpid());
    
    cout << "=== Monte Carlo Integration ===" << endl;
    cout << "Function: f(x) = x^2 * sin(x) + 1" << endl;
    cout << "Interval: [" << a << ", " << b << "]" << endl;
    cout << "Samples: " << num_samples << endl;
    
    double integral = monte_carlo_integral(a, b, num_samples);
    
    cout << "Estimated integral: " << integral << endl;
    
    ofstream outfile(argv[4]);
    if (!outfile) {
        cerr << "Error: Cannot create output file" << endl;
        return 1;
    }
    
    outfile << "FUNCTION=x^2*sin(x)+1" << endl;
    outfile << "INTERVAL_A=" << a << endl;
    outfile << "INTERVAL_B=" << b << endl;
    outfile << "SAMPLES=" << num_samples << endl;
    outfile << "INTEGRAL=" << integral << endl;
    
    outfile.close();
    
    cout << "Results written to " << argv[4] << endl;
    
    return 0;
}
