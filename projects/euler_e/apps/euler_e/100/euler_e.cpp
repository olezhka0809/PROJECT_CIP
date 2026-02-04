#include <iostream>
#include <fstream>
#include <random>
#include <cmath>
#include <iomanip>
#include <cstring>

using namespace std;

// Monte Carlo method for computing Euler's constant e
// Method: Generate random numbers until sum > 1
// Expected number of trials = e
double compute_e_monte_carlo(long long iterations) {
    random_device rd;
    mt19937_64 gen(rd());
    uniform_real_distribution<> dis(0.0, 1.0);
    
    long long total_trials = 0;
    
    for(long long i = 0; i < iterations; i++) {
        double sum = 0.0;
        int count = 0;
        while(sum < 1.0) {
            sum += dis(gen);
            count++;
        }
        total_trials += count;
    }
    
    return (double)total_trials / iterations;
}

int main(int argc, char** argv) {
    long long iterations = 1000000; // default
    
    // Parse command line arguments
    for(int i = 1; i < argc; i++) {
        if(strcmp(argv[i], "--iterations") == 0 && i+1 < argc) {
            iterations = atoll(argv[i+1]);
            i++;
        }
    }
    
    cout << "Computing Euler's constant e with " << iterations << " iterations..." << endl;
    
    double e_estimate = compute_e_monte_carlo(iterations);
    
    // Write to result.txt (BOINC default output)
    ofstream outfile("result.txt");
    outfile << fixed << setprecision(10);
    outfile << "e = " << e_estimate << endl;
    outfile << "Iterations: " << iterations << endl;
    outfile << "Error: " << fabs(e_estimate - exp(1.0)) << endl;
    outfile.close();
    
    cout << "Result: e ≈ " << e_estimate << endl;
    cout << "Actual e ≈ " << exp(1.0) << endl;
    cout << "Error: " << fabs(e_estimate - exp(1.0)) << endl;
    
    return 0;
}
