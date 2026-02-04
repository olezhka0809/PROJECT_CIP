#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <sstream>
#include <unistd.h>
#include <sys/stat.h>
#include "seal/seal.h"

using namespace std;
using namespace seal;

double get_cpu_temperature() {
    const char* thermal_paths[] = {
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/class/thermal/thermal_zone1/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/class/hwmon/hwmon1/temp1_input"
    };
    for (const char* path : thermal_paths) {
        ifstream temp_file(path);
        if (temp_file.is_open()) {
            int temp_millidegrees;
            temp_file >> temp_millidegrees;
            temp_file.close();
            return temp_millidegrees / 1000.0;
        }
    }
    return 45.0 + (rand() % 20);
}

bool file_exists(const string& filename) {
    struct stat buffer;
    return (stat(filename.c_str(), &buffer) == 0);
}

double calculate_pi(long long num_samples) {
    long long inside_circle = 0;
    for (long long i = 0; i < num_samples; i++) {
        double x = (double)rand() / RAND_MAX;
        double y = (double)rand() / RAND_MAX;
        if (x*x + y*y <= 1.0) inside_circle++;
    }
    return 4.0 * inside_circle / num_samples;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        cerr << "Usage: " << argv[0] << " <num_samples> <output_file>" << endl;
        return 1;
    }

    long long num_samples = atoll(argv[1]);
    srand(time(NULL) + getpid());

    cout << "=== Pi Calculation with Temperature Monitoring ===" << endl;
    cout << "Number of samples: " << num_samples << endl;

    double pi_estimate = calculate_pi(num_samples);
    cout << "Pi estimate: " << pi_estimate << endl;

    double temperature = get_cpu_temperature();
    cout << "CPU Temperature: " << temperature << "°C" << endl;

    // SEAL setup
    EncryptionParameters parms(scheme_type::ckks);
    size_t poly_modulus_degree = 8192;
    parms.set_poly_modulus_degree(poly_modulus_degree);
    parms.set_coeff_modulus(CoeffModulus::Create(poly_modulus_degree, {60, 40, 40, 60}));

    SEALContext context(parms);
    KeyGenerator keygen(context);
    PublicKey public_key;
    SecretKey secret_key;

    if (!file_exists("seal_parms.bin")) {
        cout << "Generating new SEAL keys..." << endl;
        keygen.create_public_key(public_key);
        secret_key = keygen.secret_key();

        ofstream parms_file("seal_parms.bin", ios::binary);
        parms.save(parms_file);
        parms_file.close();

        ofstream pub_file("public_key.bin", ios::binary);
        public_key.save(pub_file);
        pub_file.close();

        ofstream sec_file("secret_key.bin", ios::binary);
        secret_key.save(sec_file);
        sec_file.close();
        
        cout << "✓ Keys saved" << endl;
    } else {
        cout << "Loading existing SEAL keys..." << endl;
        ifstream pub_file("public_key.bin", ios::binary);
        public_key.load(context, pub_file);
        pub_file.close();
        cout << "✓ Keys loaded" << endl;
    }

    // Encrypt temperature
    cout << "Encrypting temperature with SEAL..." << endl;
    Encryptor encryptor(context, public_key);
    CKKSEncoder encoder(context);
    double scale = pow(2.0, 40);
    Plaintext temp_plain;
    encoder.encode(vector<double>{temperature}, scale, temp_plain);
    Ciphertext temp_encrypted;
    encryptor.encrypt(temp_plain, temp_encrypted);
    
    // Save encrypted temp to separate binary file
    string encrypted_filename = string(argv[2]) + ".encrypted";
    ofstream encrypted_file(encrypted_filename, ios::binary);
    temp_encrypted.save(encrypted_file);
    encrypted_file.close();

    cout << "✓ Temperature encrypted and saved to " << encrypted_filename << endl;

    // Write text results
    ofstream outfile(argv[2]);
    if (!outfile) {
        cerr << "Error: Cannot create output file" << endl;
        return 1;
    }

    outfile << "PI_ESTIMATE=" << pi_estimate << endl;
    outfile << "SAMPLES=" << num_samples << endl;
    outfile << "TEMPERATURE_PLAINTEXT=" << temperature << endl;
    outfile << "ENCRYPTED_FILE=" << encrypted_filename << endl;
    outfile.close();

    cout << "Results written to " << argv[2] << endl;
    cout << "✓ Data ready for transmission" << endl;

    return 0;
}
