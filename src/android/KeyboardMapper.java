package com.megster.cordova.ble.central;

import java.util.Dictionary;
import java.util.Hashtable;

/**
 * Created by Ares on 16/9/21.
 */
public class KeyboardMapper {
    //
// a~z

    private static final byte a97[] = {0x01, 0x00, 0x00, 0x04};
    private static final byte a98[] = {0x01, 0x00, 0x00, 0x05};
    private static final byte a99[] = {0x01, 0x00, 0x00, 0x06};
    private static final byte a100[] = {0x01, 0x00, 0x00, 0x07};
    private static final byte a101[] = {0x01, 0x00, 0x00, 0x08};
    private static final byte a102[] = {0x01, 0x00, 0x00, 0x09};
    private static final byte a103[] = {0x01, 0x00, 0x00, 0x0a};
    private static final byte a104[] = {0x01, 0x00, 0x00, 0x0b};
    private static final byte a105[] = {0x01, 0x00, 0x00, 0x0c};
    private static final byte a106[] = {0x01, 0x00, 0x00, 0x0d};
    private static final byte a107[] = {0x01, 0x00, 0x00, 0x0e};
    private static final byte a108[] = {0x01, 0x00, 0x00, 0x0f};
    private static final byte a109[] = {0x01, 0x00, 0x00, 0x10};
    private static final byte a110[] = {0x01, 0x00, 0x00, 0x11};
    private static final byte a111[] = {0x01, 0x00, 0x00, 0x12};
    private static final byte a112[] = {0x01, 0x00, 0x00, 0x13};
    private static final byte a113[] = {0x01, 0x00, 0x00, 0x14};
    private static final byte a114[] = {0x01, 0x00, 0x00, 0x15};
    private static final byte a115[] = {0x01, 0x00, 0x00, 0x16};
    private static final byte a116[] = {0x01, 0x00, 0x00, 0x17};
    private static final byte a117[] = {0x01, 0x00, 0x00, 0x18};
    private static final byte a118[] = {0x01, 0x00, 0x00, 0x19};
    private static final byte a119[] = {0x01, 0x00, 0x00, 0x1a};
    private static final byte a120[] = {0x01, 0x00, 0x00, 0x1b};
    private static final byte a121[] = {0x01, 0x00, 0x00, 0x1c};
    private static final byte a122[] = {0x01, 0x00, 0x00, 0x1d};

//
// A~Z

    private static final byte a65[] = {0x01, 0x02, 0x00, 0x04};
    private static final byte a66[] = {0x01, 0x02, 0x00, 0x05};
    private static final byte a67[] = {0x01, 0x02, 0x00, 0x06};
    private static final byte a68[] = {0x01, 0x02, 0x00, 0x07};
    private static final byte a69[] = {0x01, 0x02, 0x00, 0x08};
    private static final byte a70[] = {0x01, 0x02, 0x00, 0x09};
    private static final byte a71[] = {0x01, 0x02, 0x00, 0x0a};
    private static final byte a72[] = {0x01, 0x02, 0x00, 0x0b};
    private static final byte a73[] = {0x01, 0x02, 0x00, 0x0c};
    private static final byte a74[] = {0x01, 0x02, 0x00, 0x0d};
    private static final byte a75[] = {0x01, 0x02, 0x00, 0x0e};
    private static final byte a76[] = {0x01, 0x02, 0x00, 0x0f};
    private static final byte a77[] = {0x01, 0x02, 0x00, 0x10};
    private static final byte a78[] = {0x01, 0x02, 0x00, 0x11};
    private static final byte a79[] = {0x01, 0x02, 0x00, 0x12};
    private static final byte a80[] = {0x01, 0x02, 0x00, 0x13};
    private static final byte a81[] = {0x01, 0x02, 0x00, 0x14};
    private static final byte a82[] = {0x01, 0x02, 0x00, 0x15};
    private static final byte a83[] = {0x01, 0x02, 0x00, 0x16};
    private static final byte a84[] = {0x01, 0x02, 0x00, 0x17};
    private static final byte a85[] = {0x01, 0x02, 0x00, 0x18};
    private static final byte a86[] = {0x01, 0x02, 0x00, 0x19};
    private static final byte a87[] = {0x01, 0x02, 0x00, 0x1a};
    private static final byte a88[] = {0x01, 0x02, 0x00, 0x1b};
    private static final byte a89[] = {0x01, 0x02, 0x00, 0x1c};
    private static final byte a90[] = {0x01, 0x02, 0x00, 0x1d};

//
// 0~9

    //0
    private static final byte a48[] = {0x01, 0x00, 0x00, 0x27};
    //1
    private static final byte a49[] = {0x01, 0x00, 0x00, 0x1e};
    //2
    private static final byte a50[] = {0x01, 0x00, 0x00, 0x1f};
    //3
    private static final byte a51[] = {0x01, 0x00, 0x00, 0x20};
    //4
    private static final byte a52[] = {0x01, 0x00, 0x00, 0x21};
    //5
    private static final byte a53[] = {0x01, 0x00, 0x00, 0x22};
    //6
    private static final byte a54[] = {0x01, 0x00, 0x00, 0x23};
    //7
    private static final byte a55[] = {0x01, 0x00, 0x00, 0x24};
    //8
    private static final byte a56[] = {0x01, 0x00, 0x00, 0x25};
    //9
    private static final byte a57[] = {0x01, 0x00, 0x00, 0x26};

    //
// symbol
//!
    private static final byte a33[] = {0x01, 0x02, 0x00, 0x1e};
    //@
    private static final byte a64[] = {0x01, 0x02, 0x00, 0x1f};
    //#
    private static final byte a35[] = {0x01, 0x02, 0x00, 0x20};
    //$
    private static final byte a36[] = {0x01, 0x02, 0x00, 0x21};
    //%
    private static final byte a37[] = {0x01, 0x02, 0x00, 0x22};
    //^
    private static final byte a94[] = {0x01, 0x02, 0x00, 0x23};
    //&
    private static final byte a38[] = {0x01, 0x02, 0x00, 0x24};
    //*
    private static final byte a42[] = {0x01, 0x02, 0x00, 0x25};
    //(
    private static final byte a40[] = {0x01, 0x02, 0x00, 0x26};
    //)
    private static final byte a41[] = {0x01, 0x02, 0x00, 0x27};
    //-
    private static final byte a45[] = {0x01, 0x00, 0x00, 0x2d};
    //_
    private static final byte a95[] = {0x01, 0x02, 0x00, 0x2d};
    //=
    private static final byte a61[] = {0x01, 0x00, 0x00, 0x2e};
    //+
    private static final byte a43[] = {0x01, 0x02, 0x00, 0x2e};
    //[
    private static final byte a91[] = {0x01, 0x00, 0x00, 0x2f};
    //{
    private static final byte a123[] = {0x01, 0x02, 0x00, 0x2f};
    //]
    private static final byte a93[] = {0x01, 0x00, 0x00, 0x30};
    //}
    private static final byte a125[] = {0x01, 0x02, 0x00, 0x30};
    //-\-
    private static final byte a92[] = {0x01, 0x00, 0x00, 0x31};
    //-|-
    private static final byte a124[] = {0x01, 0x02, 0x00, 0x31};
    //'
    private static final byte a39[] = {0x01, 0x00, 0x00, 0x34};
    //"
    private static final byte a34[] = {0x01, 0x02, 0x00, 0x34};
    //`
    private static final byte a96[] = {0x01, 0x00, 0x00, 0x35};
    //~
    private static final byte a126[] = {0x01, 0x02, 0x00, 0x35};
    //,
    private static final byte a44[] = {0x01, 0x00, 0x00, 0x36};
    //<
    private static final byte a60[] = {0x01, 0x02, 0x00, 0x36};
    //.
    private static final byte a46[] = {0x01, 0x00, 0x00, 0x37};
    //>
    private static final byte a62[] = {0x01, 0x02, 0x00, 0x37};
    //-/-
    private static final byte a47[] = {0x01, 0x00, 0x00, 0x38};
    //?
    private static final byte a63[] = {0x01, 0x02, 0x00, 0x38};
    //;
    private static final byte a59[] = {0x01, 0x00, 0x00, 0x33};
    //:
    private static final byte a58[] = {0x01, 0x02, 0x00, 0x33};

//
// control

    //new line
    private static final byte a10[] = {0x01, 0x00, 0x00, 0x2c};
    //enter
    private static final byte a13[] = {0x01, 0x00, 0x00, 0x28};
    //tab
    private static final byte a9[] = {0x01, 0x00, 0x00, 0x2b};
    //space
    private static final byte a32[] = {0x01, 0x00, 0x00, 0x2c};
    //left shift
    private static final byte shift[] = {0x01, 0x02, 0x00, 0x00};
    //left alt
    private static final byte alt[] = {0x01, 0x04, 0x00, 0x00};
    //release all key
    private static final byte release_all[] = {0x00, 0x00};
    //left alt + x
    private static final byte altx[] = {0x01, 0x04, 0x00, 0x1b};

    //num pad 1~0
    private static final byte p1[] = {0x59};
    private static final byte p2[] = {0x5a};
    private static final byte p3[] = {0x5b};
    private static final byte p4[] = {0x5c};
    private static final byte p5[] = {0x5d};
    private static final byte p6[] = {0x5e};
    private static final byte p7[] = {0x5f};
    private static final byte p8[] = {0x60};
    private static final byte p9[] = {0x61};
    private static final byte p0[] = {0x62};

    public static Dictionary<Integer, byte[]> maps = new Hashtable<Integer, byte[]>();

    static {

        //a-z
        maps.put(97, a97);
        maps.put(98, a98);
        maps.put(99, a99);
        maps.put(100, a100);
        maps.put(101, a101);
        maps.put(102, a102);
        maps.put(103, a103);
        maps.put(104, a104);
        maps.put(105, a105);
        maps.put(106, a106);
        maps.put(107, a107);
        maps.put(108, a108);
        maps.put(109, a109);
        maps.put(110, a110);
        maps.put(111, a111);
        maps.put(112, a112);
        maps.put(113, a113);
        maps.put(114, a114);
        maps.put(115, a115);
        maps.put(116, a116);
        maps.put(117, a117);
        maps.put(118, a118);
        maps.put(119, a119);
        maps.put(120, a120);
        maps.put(121, a121);
        maps.put(122, a122);

        //A-Z
        maps.put(65, a65);
        maps.put(66, a66);
        maps.put(67, a67);
        maps.put(68, a68);
        maps.put(69, a69);
        maps.put(70, a70);
        maps.put(71, a71);
        maps.put(72, a72);
        maps.put(73, a73);
        maps.put(74, a74);
        maps.put(75, a75);
        maps.put(76, a76);
        maps.put(77, a77);
        maps.put(78, a78);
        maps.put(79, a79);
        maps.put(80, a80);
        maps.put(81, a81);
        maps.put(82, a82);
        maps.put(83, a83);
        maps.put(84, a84);
        maps.put(85, a85);
        maps.put(86, a86);
        maps.put(87, a87);
        maps.put(88, a88);
        maps.put(89, a89);
        maps.put(90, a90);

        //0-9
        maps.put(48, a48);
        maps.put(49, a49);
        maps.put(50, a50);
        maps.put(51, a51);
        maps.put(52, a52);
        maps.put(53, a53);
        maps.put(54, a54);
        maps.put(55, a55);
        maps.put(56, a56);
        maps.put(57, a57);

        maps.put(33, a33);
        maps.put(64, a64);
        maps.put(35, a35);
        maps.put(36, a36);
        maps.put(37, a37);
        maps.put(94, a94);
        maps.put(38, a38);
        maps.put(42, a42);
        maps.put(40, a40);
        maps.put(41, a41);
        maps.put(45, a45);
        maps.put(95, a95);
        maps.put(61, a61);
        maps.put(43, a43);
        maps.put(91, a91);
        maps.put(123, a123);
        maps.put(93, a93);
        maps.put(125, a125);
        maps.put(92, a92);
        maps.put(124, a124);
        maps.put(39, a39);
        maps.put(34, a34);
        maps.put(96, a96);
        maps.put(126, a126);
        maps.put(44, a44);
        maps.put(60, a60);
        maps.put(46, a46);
        maps.put(62, a62);
        maps.put(47, a47);
        maps.put(63, a63);
        maps.put(10, a10);
        maps.put(13, a13);
        maps.put(9, a9);
        maps.put(32, a32);
        maps.put(129, shift);
        maps.put(130, release_all);
        maps.put(131, alt);
        maps.put(132, altx);

        maps.put(200, p0);
        maps.put(201, p1);
        maps.put(202, p2);
        maps.put(203, p3);
        maps.put(204, p4);
        maps.put(205, p5);
        maps.put(206, p6);
        maps.put(207, p7);
        maps.put(208, p8);
        maps.put(209, p9);

        maps.put(58,a58);
        maps.put(59,a59);

    }

}
