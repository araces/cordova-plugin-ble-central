// (c) 2014-2016 Don Coleman
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.megster.cordova.ble.central;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Handler;

import android.provider.Settings;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PermissionHelper;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import java.util.*;

public class BLECentralPlugin extends CordovaPlugin implements BluetoothAdapter.LeScanCallback {

    //update for keyboard ble --start
    private static final byte format[] = {0x01, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    private static final byte clearAlt[] = {0x01, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    private static final byte empty[] = {0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    public static final String HIDDongle_Service = "0000fd00-0000-1000-8000-00805f9b34fb";
    public static final String HIDDongle_Write_Charateristic = "0000fd01-0000-1000-8000-00805f9b34fb";
    //update for keyboard ble --end

    // actions
    private static final String SCAN = "scan";
    private static final String START_SCAN = "startScan";
    private static final String STOP_SCAN = "stopScan";
    private static final String START_SCAN_WITH_OPTIONS = "startScanWithOptions";

    private static final String LIST = "list";

    private static final String CONNECT = "connect";
    private static final String DISCONNECT = "disconnect";

    private static final String READ = "read";
    private static final String WRITE = "write";
    private static final String WRITE_WITHOUT_RESPONSE = "writeWithoutResponse";
    private static final String WRITEEXTRADATA = "writeExtraData";

    private static final String READ_RSSI = "readRSSI";

    private static final String START_NOTIFICATION = "startNotification"; // register for characteristic notification
    private static final String STOP_NOTIFICATION = "stopNotification"; // remove characteristic notification

    private static final String IS_ENABLED = "isEnabled";
    private static final String IS_CONNECTED = "isConnected";

    private static final String SETTINGS = "showBluetoothSettings";
    private static final String ENABLE = "enable";

    private static final String START_STATE_NOTIFICATIONS = "startStateNotifications";
    private static final String STOP_STATE_NOTIFICATIONS = "stopStateNotifications";

    public static final String BluetoothGatt_Service_Ready_Action = "BluetoothGatt_Service_Ready_Action";

    private BluetoothGatt mBluetoothGatt;

    private String[] toWriteDate;

    // callbacks
    CallbackContext discoverCallback;
    private CallbackContext enableBluetoothCallback;

    private static final String TAG = "BLEPlugin";
    private static final int REQUEST_ENABLE_BLUETOOTH = 1;

    BluetoothAdapter bluetoothAdapter;

    // key is the MAC Address
    Map<String, Peripheral> peripherals = new LinkedHashMap<String, Peripheral>();

    // scan options
    boolean reportDuplicates = false;

    // Android 23 requires new permissions for BluetoothLeScanner.startScan()
    private static final String ACCESS_COARSE_LOCATION = Manifest.permission.ACCESS_COARSE_LOCATION;
    private static final int REQUEST_ACCESS_COARSE_LOCATION = 2;
    private static final int PERMISSION_DENIED_ERROR = 20;
    private CallbackContext permissionCallback;
    private UUID[] serviceUUIDs;
    private int scanSeconds;

    CallbackContext mCallbackContext;

    // Bluetooth state notification
    CallbackContext stateCallback;
    BroadcastReceiver stateReceiver;
    Map<Integer, String> bluetoothStates = new Hashtable<Integer, String>() {{
        put(BluetoothAdapter.STATE_OFF, "off");
        put(BluetoothAdapter.STATE_TURNING_OFF, "turningOff");
        put(BluetoothAdapter.STATE_ON, "on");
        put(BluetoothAdapter.STATE_TURNING_ON, "turningOn");
    }};

    public void onDestroy() {
        removeStateListener();
    }

    public void onReset() {
        removeStateListener();
    }

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {

        LOG.d(TAG, "action = " + action);
        mCallbackContext = callbackContext;
        if (bluetoothAdapter == null) {
            Activity activity = cordova.getActivity();
            BluetoothManager bluetoothManager = (BluetoothManager) activity.getSystemService(Context.BLUETOOTH_SERVICE);
            bluetoothAdapter = bluetoothManager.getAdapter();
        }

        boolean validAction = true;

        if (action.equals(SCAN)) {

            UUID[] serviceUUIDs = parseServiceUUIDList(args.getJSONArray(0));
            int scanSeconds = args.getInt(1);
            resetScanOptions();
            findLowEnergyDevices(callbackContext, serviceUUIDs, scanSeconds);

        } else if (action.equals(START_SCAN)) {

            UUID[] serviceUUIDs = parseServiceUUIDList(args.getJSONArray(0));
            resetScanOptions();
            findLowEnergyDevices(callbackContext, serviceUUIDs, -1);

        } else if (action.equals(STOP_SCAN)) {

            bluetoothAdapter.stopLeScan(this);
            callbackContext.success();

        } else if (action.equals(LIST)) {

            listKnownDevices(callbackContext);

        } else if (action.equals(CONNECT)) {

            String macAddress = args.getString(0);
            connect(callbackContext, macAddress);

        } else if (action.equals(DISCONNECT)) {

            String macAddress = args.getString(0);
            disconnect(callbackContext, macAddress);

        } else if (action.equals(READ)) {

            String macAddress = args.getString(0);
            UUID serviceUUID = uuidFromString(args.getString(1));
            UUID characteristicUUID = uuidFromString(args.getString(2));
            read(callbackContext, macAddress, serviceUUID, characteristicUUID);

        } else if (action.equals(READ_RSSI)) {

            String macAddress = args.getString(0);
            readRSSI(callbackContext, macAddress);

        } else if (action.equals(WRITE)) {

            String macAddress = args.getString(0);
            UUID serviceUUID = uuidFromString(args.getString(1));
            UUID characteristicUUID = uuidFromString(args.getString(2));
            byte[] data = args.getArrayBuffer(3);
            int type = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT;
            write(callbackContext, macAddress, serviceUUID, characteristicUUID, data, type);
        } else if (action.equals(WRITEEXTRADATA)) {
            String macAddress = args.getString(0);
            UUID serviceUUID = uuidFromString(args.getString(1));
            UUID characteristicUUID = uuidFromString(args.getString(2));
            String writeData = args.getString(3);
            String isWordMode = args.getString(4);

            String[] data = new String[2];
            data[0] = writeData;
            data[1] = isWordMode;

            int type = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE;
            writeExtraData(callbackContext, macAddress, serviceUUID, characteristicUUID, data, type);

        } else if (action.equals(WRITE_WITHOUT_RESPONSE)) {

            String macAddress = args.getString(0);
            UUID serviceUUID = uuidFromString(args.getString(1));
            UUID characteristicUUID = uuidFromString(args.getString(2));
            byte[] data = args.getArrayBuffer(3);
            int type = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE;
            write(callbackContext, macAddress, serviceUUID, characteristicUUID, data, type);

        } else if (action.equals(START_NOTIFICATION)) {

            String macAddress = args.getString(0);
            UUID serviceUUID = uuidFromString(args.getString(1));
            UUID characteristicUUID = uuidFromString(args.getString(2));
            registerNotifyCallback(callbackContext, macAddress, serviceUUID, characteristicUUID);

        } else if (action.equals(STOP_NOTIFICATION)) {

            String macAddress = args.getString(0);
            UUID serviceUUID = uuidFromString(args.getString(1));
            UUID characteristicUUID = uuidFromString(args.getString(2));
            removeNotifyCallback(callbackContext, macAddress, serviceUUID, characteristicUUID);

        } else if (action.equals(IS_ENABLED)) {

            if (bluetoothAdapter.isEnabled()) {
                callbackContext.success();
            } else {
                callbackContext.error("Bluetooth is disabled.");
            }

        } else if (action.equals(IS_CONNECTED)) {

            String macAddress = args.getString(0);

            if (peripherals.containsKey(macAddress) && peripherals.get(macAddress).isConnected()) {
                callbackContext.success();
            } else {
                callbackContext.error("Not connected.");
            }

        } else if (action.equals(SETTINGS)) {

            Intent intent = new Intent(Settings.ACTION_BLUETOOTH_SETTINGS);
            cordova.getActivity().startActivity(intent);
            callbackContext.success();

        } else if (action.equals(ENABLE)) {

            enableBluetoothCallback = callbackContext;
            Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            cordova.startActivityForResult(this, intent, REQUEST_ENABLE_BLUETOOTH);

        } else if (action.equals(START_STATE_NOTIFICATIONS)) {

            if (this.stateCallback != null) {
                callbackContext.error("State callback already registered.");
            } else {
                this.stateCallback = callbackContext;
                addStateListener();
                sendBluetoothStateChange(bluetoothAdapter.getState());
            }

        } else if (action.equals(STOP_STATE_NOTIFICATIONS)) {

            if (this.stateCallback != null) {
                // Clear callback in JavaScript without actually calling it
                PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
                result.setKeepCallback(false);
                this.stateCallback.sendPluginResult(result);
                this.stateCallback = null;
            }
            removeStateListener();
            callbackContext.success();

        } else if (action.equals(START_SCAN_WITH_OPTIONS)) {
            UUID[] serviceUUIDs = parseServiceUUIDList(args.getJSONArray(0));
            JSONObject options = args.getJSONObject(1);

            resetScanOptions();
            this.reportDuplicates = options.optBoolean("reportDuplicates", false);
            findLowEnergyDevices(callbackContext, serviceUUIDs, -1);

        } else {

            validAction = false;

        }

        return validAction;
    }

    private UUID[] parseServiceUUIDList(JSONArray jsonArray) throws JSONException {
        List<UUID> serviceUUIDs = new ArrayList<UUID>();

        for (int i = 0; i < jsonArray.length(); i++) {
            String uuidString = jsonArray.getString(i);
            serviceUUIDs.add(uuidFromString(uuidString));
        }

        return serviceUUIDs.toArray(new UUID[jsonArray.length()]);
    }

    private void onBluetoothStateChange(Intent intent) {
        final String action = intent.getAction();

        if (action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
            final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
            sendBluetoothStateChange(state);
        }
    }

    private void sendBluetoothStateChange(int state) {
        if (this.stateCallback != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, this.bluetoothStates.get(state));
            result.setKeepCallback(true);
            this.stateCallback.sendPluginResult(result);
        }
    }

    private void addStateListener() {
        if (this.stateReceiver == null) {
            this.stateReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    onBluetoothStateChange(intent);
                }
            };
        }

        try {
            IntentFilter intentFilter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
            webView.getContext().registerReceiver(this.stateReceiver, intentFilter);
        } catch (Exception e) {
            LOG.e(TAG, "Error registering state receiver: " + e.getMessage(), e);
        }
    }

    private void removeStateListener() {
        if (this.stateReceiver != null) {
            try {
                webView.getContext().unregisterReceiver(this.stateReceiver);
            } catch (Exception e) {
                LOG.e(TAG, "Error unregistering state receiver: " + e.getMessage(), e);
            }
        }
        this.stateCallback = null;
        this.stateReceiver = null;
    }

    private void connect(CallbackContext callbackContext, String macAddress) {

        Peripheral peripheral = peripherals.get(macAddress);
        if (peripheral != null) {
            peripheral.connect(callbackContext, cordova.getActivity());
        } else {
            callbackContext.error("Peripheral " + macAddress + " not found.");
        }

    }

    private void disconnect(CallbackContext callbackContext, String macAddress) {

        Peripheral peripheral = peripherals.get(macAddress);
        if (peripheral != null) {
            peripheral.disconnect();
        }
        callbackContext.success();

    }

    private void read(CallbackContext callbackContext, String macAddress, UUID serviceUUID, UUID characteristicUUID) {

        Peripheral peripheral = peripherals.get(macAddress);

        if (peripheral == null) {
            callbackContext.error("Peripheral " + macAddress + " not found.");
            return;
        }

        if (!peripheral.isConnected()) {
            callbackContext.error("Peripheral " + macAddress + " is not connected.");
            return;
        }

        //peripheral.readCharacteristic(callbackContext, serviceUUID, characteristicUUID);
        peripheral.queueRead(callbackContext, serviceUUID, characteristicUUID);

    }

    private void readRSSI(CallbackContext callbackContext, String macAddress) {

        Peripheral peripheral = peripherals.get(macAddress);

        if (peripheral == null) {
            callbackContext.error("Peripheral " + macAddress + " not found.");
            return;
        }

        if (!peripheral.isConnected()) {
            callbackContext.error("Peripheral " + macAddress + " is not connected.");
            return;
        }
        peripheral.queueReadRSSI(callbackContext);
    }

    private void write(CallbackContext callbackContext, String macAddress, UUID serviceUUID, UUID characteristicUUID,
                       byte[] data, int writeType) {

        Peripheral peripheral = peripherals.get(macAddress);

        if (peripheral == null) {
            callbackContext.error("Peripheral " + macAddress + " not found.");
            return;
        }

        if (!peripheral.isConnected()) {
            callbackContext.error("Peripheral " + macAddress + " is not connected.");
            return;
        }

        //peripheral.writeCharacteristic(callbackContext, serviceUUID, characteristicUUID, data, writeType);
        peripheral.queueWrite(callbackContext, serviceUUID, characteristicUUID, data, writeType);

    }

    private void writeExtraData(CallbackContext callbackContext, String macAddress, UUID serviceUUID, UUID characteristicUUID,
                                String[] data, int writeType) {

        //Peripheral peripheral = peripherals.get(macAddress);
        /*
        if (peripheral == null) {
            callbackContext.error("Peripheral " + macAddress + " not found.");
            return;
        }

        if (!peripheral.isConnected()) {
            peripheral.connect(callbackContext,cordova.getActivity());
            //callbackContext.error("Peripheral " + macAddress + " is not connected.");
            //return;
        }

        //peripheral.writeCharacteristic(callbackContext, serviceUUID, characteristicUUID, data, writeType);
        peripheral.queueWrite(callbackContext, serviceUUID, characteristicUUID, data, writeType);
        */

        IntentFilter filter = new IntentFilter(BluetoothGatt_Service_Ready_Action);
        cordova.getActivity().registerReceiver(gattReady, filter);

        toWriteDate = data;

        BluetoothManager mBluetoothManager = (BluetoothManager) cordova.getActivity().getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter mBluetoothAdapter;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            mBluetoothAdapter = mBluetoothManager.getAdapter();
        } else {
            mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        }

        BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(macAddress);
        mBluetoothGatt = device.connectGatt(cordova.getActivity(), true, mGattCallback);

    }

    private final BluetoothGattCallback mGattCallback = new BluetoothGattCallback() {
        @Override  //当连接上设备或者失去连接时会回调该函数
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            if (newState == BluetoothProfile.STATE_CONNECTED) { //连接成功
                mBluetoothGatt.discoverServices(); //连接成功后就去找出该设备中的服务 private BluetoothGatt mBluetoothGatt;

            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {

            }
        }

        @Override  //当设备是否找到服务时，会回调该函数
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {   //找到服务了nice to meet you ,
                Log.d(TAG, "onServicesDiscovered received: " + status + "SUCCESS");

                Intent intent = new Intent(BluetoothGatt_Service_Ready_Action);
                cordova.getActivity().sendBroadcast(intent);

                this.displayGattServices(this.getSupportedGattServices());
            } else {
                Log.d(TAG, "onServicesDiscovered received: " + status);
            }
        }

        private List<BluetoothGattService> getSupportedGattServices() {
            if (mBluetoothGatt != null) {
                return mBluetoothGatt.getServices();
            }

            return null;
        }

        private void displayGattServices(List<BluetoothGattService> bluetoothGattServices) {

            for (BluetoothGattService service : bluetoothGattServices) {
                Log.i(TAG, "UUID is " + service.getUuid());
                List<BluetoothGattCharacteristic> characteristicses = service.getCharacteristics();
                for (BluetoothGattCharacteristic characteristics : characteristicses) {
                    Log.i(TAG, "SUB UUID is \t" + characteristics.getUuid());
                }
            }

        }


        @Override  //当读取设备时会回调该函数
        public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {


        }

        @Override //当向设备Descriptor中写数据时，会回调该函数
        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            Log.d(TAG, "onDescriptorWriteonDescriptorWrite = " + status + ", descriptor =" + descriptor.getUuid().toString());
        }

        @Override //设备发出通知时会调用到该接口
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            if (characteristic.getValue() != null) {
                System.out.println(characteristic.getStringValue(0));
            }
            Log.d(TAG, "--------onCharacteristicChanged-----");
        }

        @Override
        public void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
            Log.d(TAG, "rssi = " + rssi);
        }

        @Override //当向Characteristic写数据时会回调该函数
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            Log.d(TAG, "--------write success----- status:" + status);
        }

        ;
    };


    private final BroadcastReceiver gattReady = new BroadcastReceiver() {

        @Override
        public void onReceive(Context context, Intent intent) {

            if (intent.getAction().equals(BluetoothGatt_Service_Ready_Action)) {
                if ("1".equals(toWriteDate[1])) {
                    writeDocGatt(toWriteDate[0]);
                } else {
                    writeGatt(toWriteDate[0]);
                }
            }
        }
    };


    private void writeGatt(String origion) {

        BluetoothGattService gattService = mBluetoothGatt.getService(UUID.fromString(HIDDongle_Service));


        try {
            BluetoothGattCharacteristic characteristic = gattService.getCharacteristic(UUID.fromString(HIDDongle_Write_Charateristic));
            for (int index = 0; index < origion.length(); index++) {
                String singleCharacter = origion.substring(index, index + 1);

                byte[] singleBytes = singleCharacter.getBytes("GB18030");

                Integer singleCharacterLength = singleBytes.length;
                if (singleCharacterLength > 1) {
                    String hex = bytesToHexString(singleCharacter.getBytes("GB18030"));
                    String utf8Hex = new String(hex.getBytes("UTF-8"), "UTF-8");
                    String oct = Integer.toString(Integer.parseInt(utf8Hex, 16));

                    int i = 0;
                    char[] character = oct.toCharArray();
                    for (char ch : character) {
                        byte[] aformat = format.clone();
                        aformat[1] = 0x04;

                        Integer pad_number = new Integer(String.valueOf(ch));
                        if (pad_number == 0) {
                            pad_number = 10;
                        }

                        aformat[i + 3] = (byte) (pad_number + 88);
                        characteristic.setValue(aformat);

                        mBluetoothGatt.writeCharacteristic(characteristic);
                        Thread.sleep(40);
                        characteristic.setValue(clearAlt);

                        mBluetoothGatt.writeCharacteristic(characteristic);
                        Thread.sleep(40);

                        i++;
                    }
                } else {
                    String hex = bytesToHexString(singleCharacter.getBytes("GB18030"));
                    Integer codeInt = Integer.parseInt(hex, 16);
                    byte[] assciToCode = KeyboardMapper.maps.get(codeInt);

                    if (codeInt == 10) {
                        assciToCode = KeyboardMapper.maps.get(13);
                    }

                    characteristic.setValue(assciToCode);

                    mBluetoothGatt.writeCharacteristic(characteristic);
                    Thread.sleep(40);

                }
                characteristic.setValue(empty);
                mBluetoothGatt.writeCharacteristic(characteristic);
                Thread.sleep(40);


            }
            mBluetoothGatt.close();

        } catch (Exception e) {
            e.printStackTrace();
            mBluetoothGatt.close();
            mCallbackContext.error(e.getMessage());
        }

        mCallbackContext.success();

    }

    private void writeDocGatt(String origion) {
        BluetoothGattService gattService = mBluetoothGatt.getService(UUID.fromString(HIDDongle_Service));


        try {
            BluetoothGattCharacteristic characteristic = gattService.getCharacteristic(UUID.fromString(HIDDongle_Write_Charateristic));
            for (int index = 0; index < origion.length(); index++) {
                String singleCharacter = origion.substring(index, index + 1);

                byte[] singleBytes = singleCharacter.getBytes("GB18030");

                Integer singleCharacterLength = singleBytes.length;
                if (singleCharacterLength > 1) {
                    String hex = bytesToHexString(singleCharacter.getBytes("UTF-16BE"));
                    String utf16Hex = new String(hex.getBytes("UTF-16BE"), "UTF-16BE");
                    Log.d(TAG, " HEX is " + hex);
                    int i = 0;
                    char[] character = utf16Hex.toCharArray();
                    for (char ch : character) {
                        byte[] aformat = format.clone();

                        aformat[1] = 0x00;

                        int asciiCode = (int) ch;

                        byte[] byteArray = KeyboardMapper.maps.get(asciiCode);
                        aformat[i + 3] = byteArray[3];
                        characteristic.setValue(aformat);

                        mBluetoothGatt.writeCharacteristic(characteristic);
                        Thread.sleep(40);
                        characteristic.setValue(empty);

                        mBluetoothGatt.writeCharacteristic(characteristic);
                        Thread.sleep(40);

                        i++;
                    }

                    characteristic.setValue(KeyboardMapper.maps.get(132));
                    mBluetoothGatt.writeCharacteristic(characteristic);
                    Thread.sleep(40);

                } else {
                    String hex = bytesToHexString(singleCharacter.getBytes("GB18030"));
                    Integer codeInt = Integer.parseInt(hex, 16);
                    byte[] assciToCode = KeyboardMapper.maps.get(codeInt);

                    if (codeInt == 10) {
                        assciToCode = KeyboardMapper.maps.get(13);
                    }

                    characteristic.setValue(assciToCode);

                    mBluetoothGatt.writeCharacteristic(characteristic);
                    Thread.sleep(40);

                }
                characteristic.setValue(empty);
                mBluetoothGatt.writeCharacteristic(characteristic);
                Thread.sleep(40);


            }
            mBluetoothGatt.close();

        } catch (Exception e) {
            e.printStackTrace();
            mBluetoothGatt.close();
            mCallbackContext.error(e.getMessage());
        }
        mCallbackContext.success();

    }


    public static String bytesToHexString(byte[] src) {
        StringBuilder stringBuilder = new StringBuilder("");
        if (src == null || src.length <= 0) {
            return null;
        }
        for (int i = 0; i < src.length; i++) {
            int v = src[i] & 0xFF;
            String hv = Integer.toHexString(v);
            if (hv.length() < 2) {
                stringBuilder.append(0);
            }
            stringBuilder.append(hv);
        }
        return stringBuilder.toString();
    }


    private void registerNotifyCallback(CallbackContext callbackContext, String macAddress, UUID serviceUUID, UUID characteristicUUID) {

        Peripheral peripheral = peripherals.get(macAddress);
        if (peripheral != null) {

            //peripheral.setOnDataCallback(serviceUUID, characteristicUUID, callbackContext);
            peripheral.queueRegisterNotifyCallback(callbackContext, serviceUUID, characteristicUUID);

        } else {

            callbackContext.error("Peripheral " + macAddress + " not found");

        }

    }

    private void removeNotifyCallback(CallbackContext callbackContext, String macAddress, UUID serviceUUID, UUID characteristicUUID) {

        Peripheral peripheral = peripherals.get(macAddress);
        if (peripheral != null) {

            peripheral.queueRemoveNotifyCallback(callbackContext, serviceUUID, characteristicUUID);

        } else {

            callbackContext.error("Peripheral " + macAddress + " not found");

        }

    }

    private void findLowEnergyDevices(CallbackContext callbackContext, UUID[] serviceUUIDs, int scanSeconds) {

        if (!PermissionHelper.hasPermission(this, ACCESS_COARSE_LOCATION)) {
            // save info so we can call this method again after permissions are granted
            permissionCallback = callbackContext;
            this.serviceUUIDs = serviceUUIDs;
            this.scanSeconds = scanSeconds;
            PermissionHelper.requestPermission(this, REQUEST_ACCESS_COARSE_LOCATION, ACCESS_COARSE_LOCATION);
            return;
        }

        // ignore if currently scanning, alternately could return an error
        if (bluetoothAdapter.isDiscovering()) {
            return;
        }

        // clear non-connected cached peripherals
        for (Iterator<Map.Entry<String, Peripheral>> iterator = peripherals.entrySet().iterator(); iterator.hasNext(); ) {
            Map.Entry<String, Peripheral> entry = iterator.next();
            if (!entry.getValue().isConnected()) {
                iterator.remove();
            }
        }

        discoverCallback = callbackContext;

        if (serviceUUIDs.length > 0) {
            bluetoothAdapter.startLeScan(serviceUUIDs, this);
        } else {
            bluetoothAdapter.startLeScan(this);
        }

        if (scanSeconds > 0) {
            Handler handler = new Handler();
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    LOG.d(TAG, "Stopping Scan");
                    BLECentralPlugin.this.bluetoothAdapter.stopLeScan(BLECentralPlugin.this);
                }
            }, scanSeconds * 1000);
        }

        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
    }

    private void listKnownDevices(CallbackContext callbackContext) {

        JSONArray json = new JSONArray();

        // do we care about consistent order? will peripherals.values() be in order?
        for (Map.Entry<String, Peripheral> entry : peripherals.entrySet()) {
            Peripheral peripheral = entry.getValue();
            json.put(peripheral.asJSONObject());
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, json);
        callbackContext.sendPluginResult(result);
    }

    @Override
    public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {

        String address = device.getAddress();
        boolean alreadyReported = peripherals.containsKey(address);

        if (!alreadyReported) {

            Peripheral peripheral = new Peripheral(device, rssi, scanRecord);
            peripherals.put(device.getAddress(), peripheral);

            if (discoverCallback != null) {
                PluginResult result = new PluginResult(PluginResult.Status.OK, peripheral.asJSONObject());
                result.setKeepCallback(true);
                discoverCallback.sendPluginResult(result);
            }

        } else {
            Peripheral peripheral = peripherals.get(address);
            peripheral.update(rssi, scanRecord);
            if (reportDuplicates && discoverCallback != null) {
                PluginResult result = new PluginResult(PluginResult.Status.OK, peripheral.asJSONObject());
                result.setKeepCallback(true);
                discoverCallback.sendPluginResult(result);
            }
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {

        if (requestCode == REQUEST_ENABLE_BLUETOOTH) {

            if (resultCode == Activity.RESULT_OK) {
                LOG.d(TAG, "User enabled Bluetooth");
                if (enableBluetoothCallback != null) {
                    enableBluetoothCallback.success();
                }
            } else {
                LOG.d(TAG, "User did *NOT* enable Bluetooth");
                if (enableBluetoothCallback != null) {
                    enableBluetoothCallback.error("User did not enable Bluetooth");
                }
            }

            enableBluetoothCallback = null;
        }
    }

    /* @Override */
    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) /* throws JSONException */ {
        for (int result : grantResults) {
            if (result == PackageManager.PERMISSION_DENIED) {
                LOG.d(TAG, "User *rejected* Coarse Location Access");
                this.permissionCallback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, PERMISSION_DENIED_ERROR));
                return;
            }
        }

        switch (requestCode) {
            case REQUEST_ACCESS_COARSE_LOCATION:
                LOG.d(TAG, "User granted Coarse Location Access");
                findLowEnergyDevices(permissionCallback, serviceUUIDs, scanSeconds);
                this.permissionCallback = null;
                this.serviceUUIDs = null;
                this.scanSeconds = -1;
                break;
        }
    }

    private UUID uuidFromString(String uuid) {
        return UUIDHelper.uuidFromString(uuid);
    }

    /**
     * Reset the BLE scanning options
     */
    private void resetScanOptions() {
        this.reportDuplicates = false;
    }

}
