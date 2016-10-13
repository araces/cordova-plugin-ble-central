package com.megster.cordova.ble.central;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Created by Ares on 2016/10/11.
 */

public class Utils {

    public static final String MainKeyName = "BLEDEVICEINFO";
    public static final String StringEmpty = "";

    public static final String HIDDongle_Service="0000fd00-0000-1000-8000-00805f9b34fb";
    public static final String HIDDongle_Write_Charateristic="0000fd01-0000-1000-8000-00805f9b34fb";


    public static void saveLocalData(Context context, String key, String value) {
        SharedPreferences sharedPreferences = context.getSharedPreferences(MainKeyName, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(key, value);
        editor.commit();
    }

    public static String getLocalData(Context context,String key){
        SharedPreferences sharedPreferences = context.getSharedPreferences(MainKeyName, Context.MODE_PRIVATE);
        return sharedPreferences.getString(key,"");
    }

    public static void clearLocalData(Context context){
        SharedPreferences sharedPreferences = context.getSharedPreferences(MainKeyName, Context.MODE_PRIVATE);
        sharedPreferences.edit().clear().commit();
    }

    public static boolean IsEmpty(String context){
        if(null == context){
            return true;
        }
        if(context.trim().length() == 0){
            return true;
        }

        return false;
    }
}
