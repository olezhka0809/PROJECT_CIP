#include <iostream>
#include <random>
#include <cmath>
#include <fstream>
#include <iomanip>

double calculate_e_monte_carlo(long long iterations) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> dis(0.0, 1.0);
    
    long long count = 0;
    for(long long i = 0; i < iterations; i++) {
        double sum = 0;
        int draws = 0;
        while(sum < 1.0) {
            sum += dis(gen);
            draws++;
        }
        count += draws;
    }
    return (double)count / iterations;
}

int main(int argc, char** argv) {
    long long iterations = 1000000;
    
    if(argc > 1) {
        iterations = std::stoll(argv[1]);
    }
    
    double e_approx = calculate_e_monte_carlo(iterations);
    
    std::ofstream outfile("result.txt");
    outfile << std::fixed << std::setprecision(10);
    outfile << "e ≈ " << e_approx << std::endl;
    outfile << "Iterations: " << iterations << std::endl;
    outfile << "Error: " << std::abs(e_approx - M_E) << std::endl;
    outfile.close();
    
    std::cout << "e ≈ " << e_approx << " (actual: " << M_E << ")" << std::endl;
    
    return 0;
}
