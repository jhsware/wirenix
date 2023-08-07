{ config, lib, pkgs, ... }: 
with lib;
let
  has-rekey = config ? rekey;
  peerOpts = {
    options = {
      subnets = mkOption {
        default = [];
        type = with types; listOf str;
        description = ''
          subnets the peer belongs to
        '';
      };
      groups = mkOption {
        default = true;
        type = with types; listOf str;
        description = ''
          groups the peer belongs to
        '';
      };
      peers = {
        default = true;
        type = with types; listOf set;
        description = mdDoc ''
          Peers the peer is connected to, can be one of `{ peer = "peerName"; }`
          or `{ group = "groupname"; }`. Remember to configure this for *both* peers.
          The best way to do this is with a simple full mesh network, where all peers
          belong to one group ("groupA"), and their peers are `{ group = "groupA"}`.
          '';
      };
      privateKeyFile = mkOption {
        example = "/private/wireguard_key";
        type = with types; nullOr str;
        default = null;
        description = mdDoc ''
          Private key file as generated by {command}`wg genkey`.
        '';
      };
      name = mkOption {
        example = "bernd";
        type = types.str;
        description = mdDoc "Unique name for the peer (must be unique for all subdomains this peer is a member of)";
      };
      endpoints = mkOption {
        example = ''
          [
          {match = {}; ip = "192.168.1.10"; port = 51820;} # default case            
          {match = {group = "location1"; subnet = "lanNet";}; ip = "192.168.1.10"; port = 51820; }
          {match = {peer = "offSitePeer1";}; ip = "123.123.123.123"; port = 51825; persistentKeepalive = 15;}
          ];
        '';
        type = with types; listOf attrset;
        description = mdDoc ''
          The endpoints clients use to reach this host with rules to match by
          group name `match = {group = "groupName";};`
          peer name `match = {peer = "peerName";};`
          or a default match at the end `match = {};`
          All rules in `match` must be true for a match to happen.
          Multiple matches will be merged top to bottom, so rules at the top
          should be your most general rules which get overridden. 
          Values other than `match` specify options for the connection,
          possible values are:  
          - ip  
          - port  
          - persistentKeepalive  
          - dynamicEndpointRefreshSeconds  
          - dynamicEndpointRefreshRestartSeconds  
        '';
      };
      publicKey = mkOption {
        example = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
        type = types.singleLineStr;
        description = mdDoc "The base64 public key of the peer.";
      };
      presharedKeyFile = mkOption {
        default = null;
        example = "/private/wireguard_psk";
        type = with types; nullOr str;
        description = mdDoc ''
          File pointing to preshared key as generated by {command}`wg genpsk`.
          Optional, and may be omitted. This option adds an additional layer of
          symmetric-key cryptography to be mixed into the already existing
          public-key cryptography, for post-quantum resistance.
        '';
      };
    };
  };
  subnetOpts = {
    options = {
      name = mkOption {
        default = "wireguard";
        example = "mySubnet.myDomain.me";
        type = types.str;
        description = mdDoc "Unique name for the subnet";
      };
      defaultPort = mkOption {
        example = 51820;
        type = types.int;
        description = mdDoc ''
          The port peers will use when communicating over this subnet.
          Currently there is no way to set the ports for peers individually.
        '';
      };
    };
  };
  configOpts = {
    options = {
      subnets = mkOption {
        default = {};
        type = with types; listOf (submodule subnetOpts);
        description = ''
          Subnets in the mesh network(s)
        '';
      };
      peers = mkOption {
        default = {};
        type = with types; listOf (submodule peerOpts);
        description = ''
          Peers in the mesh network(s)
        '';
      };
    };
  };
in
{
  options = {
    wirenix = {
      enable = mkOption {
        default = true;
        type = with lib.types; bool;
        description = ''
          Wirenix
        '';
      };
      peerName = mkOption {
        default = config.networking.hostName;
        defaultText = literalExpression "hostName";
        example = "bernd";
        type = types.str;
        description = mdDoc ''
          Name of the peer using this module, to match the name in
          `wirenix.config.peers.*.name`
        '';
      };
      config = mkOption {
        default = {};
        type = with types; setOf (submodule configOpts);
        description = ''
          Shared configuration file that describes all clients
        '';
      };
    };
  };
  
  # --------------------------------------------------------------- #
  
  config = lib.mkIf (config.modules.wirenix.enable) (lib.mkMerge [
    (lib.mkIf (has-rekey) {
      environment.etc.rekey.text = "yes";
    })
    (lib.mkIf (!has-rekey ) {
      environment.etc.rekey.text = "no";
    })
  ]);
}