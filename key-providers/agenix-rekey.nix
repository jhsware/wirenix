/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
{config, lib, ...}: intermediateConfig: peerName:
with (import ../lib.nix);
with lib.attrsets;
with builtins;
{
  config.age = {
    secrets = {
      "wirenix-peer-${peerName}" = {
        rekeyFile = config.wirenix.secretsDir + /wirenix-peer- + peerName + ".age";
        generator.script = {pkgs, file, ...}: ''
          priv=$(${pkgs.wireguard-tools}/bin/wg genkey)
          ${pkgs.wireguard-tools}/bin/wg pubkey <<< "$priv" > ${lib.escapeShellArg (lib.removeSuffix ".age" file + ".pub")}
          echo "$priv"
        '';
      };
    } // 
    mapAttrs' (name: value: nameValuePair ("wirenix-subnet-${name}") {
        rekeyFile = config.wirenix.secretsDir + /wirenix-subnet- + name + ".age";
        generator.script = {pkgs, ...}: ''
          psk=$(${pkgs.wireguard-tools}/bin/wg genpsk)
          echo "$psk"
        '';
      }) intermediateConfig.peers."${peerName}".subnetConnections;  
    };
  getPeerPubKey    = otherPeerName: builtins.readFile (config.wirenix.secretsDir + /wirenix-peer-${peerName}.pub);
  getPrivKeyFile   = config.age.secrets."wirenix-peer-${peerName}".path;
  getSubnetPSKFile = subnetName: config.age.secrets."wirenix-subnet-${subnetName}".path;
}