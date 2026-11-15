// La configuración vive en app.json. Este archivo solo cambia dos cosas según el build:
//   APP_CANAL=production → el AAB de Google Play escucha el canal "production" de EAS Update.
//     Sin APP_CANAL queda el de app.json ("preview"): el APK normal de uso, donde se prueba primero.
//     Así una OTA a "preview" no les llega a los clientes de Play hasta que se republica en
//     "production" (eas update:republish ... --destination-channel production).
//   APP_VARIANTE=pruebas → app aparte («(Pruebas)», otro paquete) que se instala junto a la de
//     producción, acepta servidores http:// (Laragon en la red local) y no recibe actualizaciones OTA
//     (una OTA del canal preview le metería el código de producción y apuntaría al servidor real).
// Sin variables la configuración queda exactamente como en app.json (APK normal y EAS).
module.exports = ({ config }) => {
  if (process.env.APP_VARIANTE === 'pruebas') {
    return {
      ...config,
      name: `${config.name} (Pruebas)`,
      android: { ...config.android, package: `${config.android.package}.pruebas` },
      updates: { ...config.updates, enabled: false },
      plugins: [...(config.plugins ?? []), './plugins/withHttpLocal'],
    };
  }

  if (process.env.APP_CANAL) {
    return {
      ...config,
      updates: {
        ...config.updates,
        requestHeaders: { ...config.updates?.requestHeaders, 'expo-channel-name': process.env.APP_CANAL },
      },
    };
  }

  return config;
};
