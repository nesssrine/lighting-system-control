// =====================================================================
//  Noeud ROS 2 "lsc_ecu" : le calculateur d'eclairage (Lighting System Control)
//  Execute toutes les 10 ms le code C genere par Embedded Coder (le meme que
//  celui valide en SIL) : runnable LSC_cmd (B1,B2,B3,B4/B8,B5,B7) puis LSC_diag (B6).
//  Entrees  : /lsc/in/*  (capteurs du vehicule virtuel, publies par Webots)
//             /lsc/cmd/* (commandes du conducteur : commodo, clignotants...)
//  Sorties  : /lsc/out/* (PWM des lampes, etat des feux, AHB, DTC...)
//  Auteur : Amina Borcheni - PFE M2 IAA ENET'Com
// =====================================================================
#include <chrono>
#include <cmath>
#include <memory>
#include <vector>
#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/bool.hpp"
#include "std_msgs/msg/float64.hpp"
#include "std_msgs/msg/int32.hpp"
#include "std_msgs/msg/u_int8.hpp"
#include "std_msgs/msg/u_int16.hpp"
#include "std_msgs/msg/u_int8_multi_array.hpp"

extern "C" {
#include "LSC_cmd.h"
#include "LSC_diag.h"
#include "Plant_Lamps.h"
#include "LSC_ECU_initialize.h"
}

using namespace std::chrono_literals;
using std_msgs::msg::Bool;
using std_msgs::msg::Float64;
using std_msgs::msg::Int32;

class LscEcuNode : public rclcpp::Node {
public:
  LscEcuNode() : Node("lsc_ecu") {
    LSC_ECU_initialize();
    // --- entrees capteurs (vehicule virtuel)
    subF("/lsc/in/lux", lux_);  subF("/lsc/in/speed", speed_);  subF("/lsc/in/decel", decel_);  subF("/lsc/in/vbat", vbat_);
    subB("/lsc/in/vehicle_detected", veh_cam_);  subB("/lsc/in/cam_ok", cam_ok_);
    // --- commandes conducteur / scenario
    subB("/lsc/cmd/ignition", ign_);  subB("/lsc/cmd/flash", flash_);  subB("/lsc/cmd/hb_toggle", hb_);
    subB("/lsc/cmd/fog", fog_);  subB("/lsc/cmd/ahb_switch", ahb_sw_);  subB("/lsc/cmd/turn_left", tl_);
    subB("/lsc/cmd/turn_right", tr_);  subB("/lsc/cmd/hazard", haz_sw_);  subB("/lsc/cmd/brake", brake_);
    subB("/lsc/cmd/door_closed", door_);  subB("/lsc/cmd/vehicle", veh_man_);  subB("/lsc/cmd/cam_fault", cam_fault_);
    subB("/lsc/cmd/lamp_fail_right", lamp_fail_r_);  subB("/lsc/cmd/sensor_fault", sensor_fault_);
    lf_sub_ = create_subscription<Int32>("/lsc/cmd/lamp_fail", 10, [this](Int32::SharedPtr m) { lamp_mask_ = m->data; });
    sw_sub_ = create_subscription<Int32>("/lsc/cmd/light_switch", 10, [this](Int32::SharedPtr m) { sw_ = m->data; });
    // --- sorties
    duty_pub_ = create_publisher<std_msgs::msg::UInt8MultiArray>("/lsc/out/duty", 10);
    state_pub_ = create_publisher<std_msgs::msg::UInt8>("/lsc/out/light_state", 10);
    ahb_pub_ = create_publisher<std_msgs::msg::UInt8>("/lsc/out/ahb_state", 10);
    dtc_pub_ = create_publisher<std_msgs::msg::UInt16>("/lsc/out/dtc", 10);
    luxf_pub_ = create_publisher<Float64>("/lsc/out/lux_filt", 10);
    haz_pub_ = create_publisher<Bool>("/lsc/out/hazard", 10);
    ess_pub_ = create_publisher<Bool>("/lsc/out/ess", 10);
    fmh_pub_ = create_publisher<Bool>("/lsc/out/fmh", 10);
    warn_pub_ = create_publisher<Bool>("/lsc/out/warning", 10);
    timer_ = create_wall_timer(10ms, std::bind(&LscEcuNode::step, this));   // tache periodique 10 ms
    RCLCPP_INFO(get_logger(), "Calculateur LSC demarre : code C Embedded Coder, periode 10 ms");
  }

private:
  void subF(const char *t, double &v) {
    subs_.push_back(create_subscription<Float64>(t, 10, [&v](Float64::SharedPtr m) { v = m->data; }));
  }
  void subB(const char *t, bool &v) {
    subs_.push_back(create_subscription<Bool>(t, 10, [&v](Bool::SharedPtr m) { v = m->data; }));
  }

  void step() {
    unsigned char duty[8], lst, ahb, deg; double veff, luxf, cur[4];
    boolean_T dcmd[4], fmh, haz, ess, fa[4], wn; unsigned short dtc;
    const boolean_T veh = veh_cam_ || veh_man_;
    const boolean_T cam = cam_ok_ && !cam_fault_;
    // Runnable 1 : B1 -> B2 -> B3 -> B4/B8 -> B5 -> B7
    LSC_cmd(ign_, (double)sw_, flash_, hb_, fog_, ahb_sw_, tl_, tr_, haz_sw_, brake_,
            lux_, !sensor_fault_, speed_, decel_, veh, cam, door_, vbat_, fault_prev_, deg_prev_,
            duty, &veff, dcmd, &lst, &fmh, &ahb, &haz, &ess, &luxf);
    // Retour courant des lampes (modele des ampoules, remplace la mesure du driver de puissance)
    // masque des ampoules grillees : 1 croisement G, 2 croisement D, 4 clignotant G, 8 clignotant D
    double lf[4] = {(lamp_mask_ & 1) ? 0.0 : 1.0, (lamp_fail_r_ || (lamp_mask_ & 2)) ? 0.0 : 1.0,
                    (lamp_mask_ & 4) ? 0.0 : 1.0, (lamp_mask_ & 8) ? 0.0 : 1.0};
    Plant_Lamps(duty, vbat_, lf, cur);
    // Runnable 2 : B6 diagnostic
    LSC_diag(dcmd, cur, false, fa, &dtc, &deg, &wn);
    for (int i = 0; i < 4; i++) fault_prev_[i] = fa[i];      // RTE : disponible au pas suivant
    deg_prev_ = deg;

    std_msgs::msg::UInt8MultiArray d; d.data.assign(duty, duty + 8); duty_pub_->publish(d);
    std_msgs::msg::UInt8 u; u.data = lst; state_pub_->publish(u); u.data = ahb; ahb_pub_->publish(u);
    std_msgs::msg::UInt16 w; w.data = dtc; dtc_pub_->publish(w);
    Float64 f; f.data = luxf; luxf_pub_->publish(f);
    Bool b; b.data = haz; haz_pub_->publish(b); b.data = ess; ess_pub_->publish(b);
    b.data = fmh; fmh_pub_->publish(b); b.data = wn; warn_pub_->publish(b);
  }

  // valeurs par defaut : contact mis, commodo AUTO, AHB autorise, porte fermee, batterie 14,2 V
  double lux_ = 20000.0, speed_ = 0.0, decel_ = 0.0, vbat_ = 14.2;
  bool veh_cam_ = false, cam_ok_ = true, ign_ = true, flash_ = false, hb_ = false, fog_ = false, ahb_sw_ = true;
  bool tl_ = false, tr_ = false, haz_sw_ = false, brake_ = false, door_ = true, veh_man_ = false, cam_fault_ = false;
  bool lamp_fail_r_ = false, sensor_fault_ = false;
  int lamp_mask_ = 0;
  int sw_ = 1;
  boolean_T fault_prev_[4] = {0, 0, 0, 0};
  unsigned char deg_prev_ = 0;
  std::vector<rclcpp::SubscriptionBase::SharedPtr> subs_;
  rclcpp::Subscription<Int32>::SharedPtr sw_sub_, lf_sub_;
  rclcpp::Publisher<std_msgs::msg::UInt8MultiArray>::SharedPtr duty_pub_;
  rclcpp::Publisher<std_msgs::msg::UInt8>::SharedPtr state_pub_, ahb_pub_;
  rclcpp::Publisher<std_msgs::msg::UInt16>::SharedPtr dtc_pub_;
  rclcpp::Publisher<Float64>::SharedPtr luxf_pub_;
  rclcpp::Publisher<Bool>::SharedPtr haz_pub_, ess_pub_, fmh_pub_, warn_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char **argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<LscEcuNode>());
  rclcpp::shutdown();
  return 0;
}
